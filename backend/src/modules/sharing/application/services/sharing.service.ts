import {
  Injectable,
  NotFoundException,
  GoneException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as QRCode from 'qrcode';

import { PrismaService } from '../../../../common/prisma/prisma.service';
import { DesignRepository } from '../../../catalog/infrastructure/repositories/design.repository';
import { S3StorageService } from '../../../catalog/application/services/s3-storage.service';
import {
  CreateShareDto,
  ShareResponseDto,
  SharedDesignResponseDto,
} from '../dto/sharing.dto';

/**
 * Sharing service — core business logic for the Sharing bounded context.
 *
 * Domain rules:
 * - Only the design owner can create share tokens.
 * - Tokens have a TTL (time-to-live) and maxUses counter.
 * - Token consumption is atomic (prevents race conditions on maxUses).
 * - Expired or exhausted tokens return 410 Gone.
 * - Revoked tokens return 410 Gone.
 * - The presigned S3 URL is generated on-demand with a 5-minute TTL.
 */
@Injectable()
export class SharingService {
  private readonly logger = new Logger(SharingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly designRepository: DesignRepository,
    private readonly s3Storage: S3StorageService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Create a share token for a design.
   *
   * Generates a unique token and a QR code containing the deep link.
   */
  async createShareToken(
    dto: CreateShareDto,
    artistProfileId: string,
  ): Promise<ShareResponseDto> {
    // Verify design ownership
    const design = await this.designRepository.findById(dto.designId);
    if (!design) {
      throw new NotFoundException('Design not found');
    }
    if (design.artistId !== artistProfileId) {
      throw new ForbiddenException('You do not own this design');
    }

    const defaultTtl = this.configService.get<number>('share.defaultTtl', 86400);
    const ttl = dto.ttlSeconds ?? defaultTtl;
    const maxUses = dto.maxUses ?? 1;

    const expiresAt = new Date(Date.now() + ttl * 1000);

    // Create token in database
    const shareToken = await this.prisma.shareToken.create({
      data: {
        designId: dto.designId,
        maxUses,
        expiresAt,
      },
    });

    // Generate deep link
    const deepLink = `inksight://share/${shareToken.token}`;

    // Generate QR code as data URL
    const qrCodeDataUrl = await QRCode.toDataURL(deepLink, {
      width: 512,
      margin: 2,
      color: {
        dark: '#8B5CF6',  // Electric violet (brand color)
        light: '#0A0A0F', // Dark surface
      },
      errorCorrectionLevel: 'H', // High — allows up to 30% damage
    });

    this.logger.log(
      `Share token created for design ${dto.designId}: ` +
      `token=${shareToken.token}, maxUses=${maxUses}, ttl=${ttl}s`,
    );

    return {
      token: shareToken.token,
      qrCodeDataUrl,
      expiresAt,
      maxUses,
      deepLink,
    };
  }

  /**
   * Consume a share token and return the presigned design URL.
   *
   * This is the endpoint clients call after scanning a QR code.
   * Token validation is strict:
   * - Must exist and not be revoked.
   * - Must not be expired.
   * - Must have remaining uses.
   *
   * The `currentUses` counter is incremented atomically to prevent
   * race conditions with concurrent requests.
   */
  async consumeShareToken(token: string): Promise<SharedDesignResponseDto> {
    // Atomic find-and-increment to prevent race conditions
    const shareToken = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.shareToken.findUnique({
        where: { token },
        include: {
          design: {
            include: {
              artist: true,
            },
          },
        },
      });

      if (!existing) {
        throw new NotFoundException('Share link not found');
      }

      if (existing.isRevoked) {
        throw new GoneException('This share link has been revoked');
      }

      if (existing.expiresAt < new Date()) {
        throw new GoneException('This share link has expired');
      }

      if (existing.currentUses >= existing.maxUses) {
        throw new GoneException('This share link has been used the maximum number of times');
      }

      // Atomic increment
      await tx.shareToken.update({
        where: { id: existing.id },
        data: {
          currentUses: { increment: 1 },
          lastUsedAt: new Date(),
        },
      });

      return existing;
    });

    // Generate presigned URL (5-minute TTL)
    const presignedUrl = await this.s3Storage.generatePresignedUrl(
      shareToken.design.s3Key,
    );

    const artist = shareToken.design.artist;

    return {
      presignedUrl,
      metadata: {
        id: shareToken.design.id,
        title: shareToken.design.title,
        style: shareToken.design.style,
        widthPx: shareToken.design.widthPx,
        heightPx: shareToken.design.heightPx,
        artistName: artist?.studioName ?? 'Unknown Artist',
        recommendedBodyParts: shareToken.design.recommendedBodyParts,
        estimatedWidthCm: shareToken.design.estimatedWidthCm ?? undefined,
        estimatedHeightCm: shareToken.design.estimatedHeightCm ?? undefined,
      },
    };
  }

  /**
   * Revoke a share token (artist action).
   */
  async revokeToken(tokenId: string, artistProfileId: string): Promise<void> {
    const shareToken = await this.prisma.shareToken.findUnique({
      where: { id: tokenId },
      include: { design: true },
    });

    if (!shareToken) throw new NotFoundException('Token not found');
    if (shareToken.design.artistId !== artistProfileId) {
      throw new ForbiddenException();
    }

    await this.prisma.shareToken.update({
      where: { id: tokenId },
      data: { isRevoked: true },
    });

    this.logger.log(`Share token revoked: ${tokenId}`);
  }
}
