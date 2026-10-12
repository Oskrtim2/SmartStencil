import { Injectable } from '@nestjs/common';
import { DesignStatus, DesignStyle, Prisma } from '@prisma/client';

import { PrismaService } from '../../../../common/prisma/prisma.service';

interface CreateDesignInput {
  artistId: string;
  title: string;
  description?: string;
  style: DesignStyle;
  s3Key: string;
  s3Bucket: string;
  originalFilename: string;
  mimeType: string;
  fileSizeBytes: number;
  widthPx: number;
  heightPx: number;
  recommendedBodyParts: string[];
  estimatedWidthCm?: number;
  estimatedHeightCm?: number;
  tags: string[];
}

interface FindByArtistOptions {
  style?: DesignStyle;
  search?: string;
  limit: number;
  offset: number;
}

/**
 * Repository for Design aggregate in the Catalog bounded context.
 */
@Injectable()
export class DesignRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a design with associated tags in a transaction.
   */
  async create(input: CreateDesignInput) {
    return this.prisma.$transaction(async (tx) => {
      const design = await tx.design.create({
        data: {
          artistId: input.artistId,
          title: input.title,
          description: input.description,
          style: input.style,
          status: DesignStatus.DRAFT,
          s3Key: input.s3Key,
          s3Bucket: input.s3Bucket,
          originalFilename: input.originalFilename,
          mimeType: input.mimeType,
          fileSizeBytes: input.fileSizeBytes,
          widthPx: input.widthPx,
          heightPx: input.heightPx,
          recommendedBodyParts: input.recommendedBodyParts,
          estimatedWidthCm: input.estimatedWidthCm,
          estimatedHeightCm: input.estimatedHeightCm,
        },
      });

      // Create tags
      if (input.tags.length > 0) {
        await tx.designTag.createMany({
          data: input.tags.map((tag) => ({
            designId: design.id,
            tag: tag.toLowerCase().trim(),
          })),
        });
      }

      return design;
    });
  }

  /**
   * Find a design by ID with tags.
   */
  async findById(id: string) {
    return this.prisma.design.findUnique({
      where: { id },
      include: { tags: true },
    });
  }

  /**
   * Find designs by artist with filtering.
   */
  async findByArtist(artistId: string, options: FindByArtistOptions) {
    const where: Prisma.DesignWhereInput = {
      artistId,
      ...(options.style ? { style: options.style } : {}),
      ...(options.search
        ? {
            OR: [
              { title: { contains: options.search, mode: 'insensitive' as const } },
              { tags: { some: { tag: { contains: options.search, mode: 'insensitive' as const } } } },
            ],
          }
        : {}),
    };

    return this.prisma.design.findMany({
      where,
      include: { tags: true },
      orderBy: { createdAt: 'desc' },
      take: options.limit,
      skip: options.offset,
    });
  }

  /**
   * Find a design by S3 key (for reverse lookups).
   */
  async findByS3Key(s3Key: string) {
    return this.prisma.design.findUnique({
      where: { s3Key },
    });
  }

  /**
   * Update design status.
   */
  async updateStatus(id: string, status: DesignStatus) {
    return this.prisma.design.update({
      where: { id },
      data: { status },
    });
  }

  /**
   * Delete a design and its tags (cascade).
   */
  async delete(id: string) {
    return this.prisma.design.delete({
      where: { id },
    });
  }
}
