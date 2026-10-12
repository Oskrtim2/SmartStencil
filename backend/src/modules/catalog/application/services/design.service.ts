import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DesignStatus } from '@prisma/client';
import * as sharp from 'sharp';

import { DesignRepository } from '../../infrastructure/repositories/design.repository';
import { S3StorageService } from './s3-storage.service';
import { CreateDesignDto, DesignResponseDto, DesignListQueryDto } from '../dto/design.dto';

interface UploadedFile {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
  size: number;
}

interface AuthenticatedUser {
  id: string;
  role: string;
}

/**
 * Design service — core business logic for the Catalog bounded context.
 *
 * Domain rules:
 * - Only artists can upload designs.
 * - Only the owning artist can modify/delete their designs.
 * - PNG files are validated (magic bytes + dimensions).
 * - Maximum file size: 50MB.
 * - Designs start in DRAFT status.
 */
@Injectable()
export class DesignService {
  private readonly logger = new Logger(DesignService.name);
  private static readonly MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
  private static readonly PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47]);

  constructor(
    private readonly designRepository: DesignRepository,
    private readonly s3Storage: S3StorageService,
  ) {}

  /**
   * Upload a new tattoo design.
   */
  async createDesign(
    dto: CreateDesignDto,
    file: UploadedFile,
    artistProfileId: string,
  ): Promise<DesignResponseDto> {
    // Validate file
    this.validatePngFile(file);

    // Extract image dimensions
    const metadata = await this.extractImageMetadata(file.buffer);

    // Upload to S3
    const { s3Key, bucket } = await this.s3Storage.uploadDesignPng(
      file.buffer,
      file.originalname,
      artistProfileId,
    );

    // Create design entity
    const design = await this.designRepository.create({
      artistId: artistProfileId,
      title: dto.title,
      description: dto.description,
      style: dto.style,
      s3Key,
      s3Bucket: bucket,
      originalFilename: file.originalname,
      mimeType: file.mimetype,
      fileSizeBytes: file.size,
      widthPx: metadata.width,
      heightPx: metadata.height,
      recommendedBodyParts: dto.recommendedBodyParts ?? [],
      estimatedWidthCm: dto.estimatedWidthCm,
      estimatedHeightCm: dto.estimatedHeightCm,
      tags: dto.tags ?? [],
    });

    this.logger.log(`Design created: ${design.id} by artist ${artistProfileId}`);

    return this.toResponseDto(design);
  }

  /**
   * List designs for an artist with optional filtering.
   */
  async listByArtist(
    artistProfileId: string,
    query: DesignListQueryDto,
  ): Promise<DesignResponseDto[]> {
    const designs = await this.designRepository.findByArtist(
      artistProfileId,
      {
        style: query.style,
        search: query.search,
        limit: query.limit ?? 20,
        offset: query.offset ?? 0,
      },
    );

    return designs.map((d) => this.toResponseDto(d));
  }

  /**
   * Get a single design by ID (artist-owned).
   */
  async getDesign(designId: string, artistProfileId: string): Promise<DesignResponseDto> {
    const design = await this.designRepository.findById(designId);
    if (!design) {
      throw new NotFoundException('Design not found');
    }
    if (design.artistId !== artistProfileId) {
      throw new ForbiddenException('You do not own this design');
    }
    return this.toResponseDto(design);
  }

  /**
   * Publish a design (make it shareable).
   */
  async publishDesign(designId: string, artistProfileId: string): Promise<void> {
    const design = await this.designRepository.findById(designId);
    if (!design) throw new NotFoundException('Design not found');
    if (design.artistId !== artistProfileId) throw new ForbiddenException();

    await this.designRepository.updateStatus(designId, DesignStatus.PUBLISHED);
  }

  /**
   * Delete a design and its S3 asset.
   */
  async deleteDesign(designId: string, artistProfileId: string): Promise<void> {
    const design = await this.designRepository.findById(designId);
    if (!design) throw new NotFoundException('Design not found');
    if (design.artistId !== artistProfileId) throw new ForbiddenException();

    await this.s3Storage.deleteDesign(design.s3Key);
    await this.designRepository.delete(designId);

    this.logger.log(`Design deleted: ${designId}`);
  }

  // ── Private helpers ───────────────────────────────

  private validatePngFile(file: UploadedFile): void {
    if (file.size > DesignService.MAX_FILE_SIZE) {
      throw new BadRequestException('File size exceeds 50MB limit');
    }

    if (file.mimetype !== 'image/png') {
      throw new BadRequestException('Only PNG files are accepted');
    }

    // Validate PNG magic bytes
    const header = file.buffer.subarray(0, 4);
    if (!header.equals(DesignService.PNG_MAGIC)) {
      throw new BadRequestException('Invalid PNG file');
    }
  }

  private async extractImageMetadata(buffer: Buffer): Promise<{ width: number; height: number }> {
    // Using the PNG IHDR chunk directly (bytes 16-23)
    // Width: bytes 16-19 (big-endian uint32)
    // Height: bytes 20-23 (big-endian uint32)
    if (buffer.length < 24) {
      throw new BadRequestException('Invalid PNG file: too small');
    }

    const width = buffer.readUInt32BE(16);
    const height = buffer.readUInt32BE(20);

    if (width === 0 || height === 0 || width > 16384 || height > 16384) {
      throw new BadRequestException(
        `Invalid image dimensions: ${width}x${height}. Max 16384px per side.`,
      );
    }

    return { width, height };
  }

  private toResponseDto(design: any): DesignResponseDto {
    return {
      id: design.id,
      title: design.title,
      description: design.description,
      style: design.style,
      widthPx: design.widthPx,
      heightPx: design.heightPx,
      thumbnailUrl: design.thumbnailS3Key ?? null,
      recommendedBodyParts: design.recommendedBodyParts ?? [],
      createdAt: design.createdAt,
    };
  }
}
