import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

/**
 * S3 storage service for managing tattoo design assets.
 *
 * Responsibilities:
 * - Upload high-res PNGs with server-side encryption (AES-256).
 * - Generate time-limited presigned GET URLs for secure client access.
 * - Delete assets when designs are removed.
 *
 * All objects are stored with private ACL — no public access.
 */
@Injectable()
export class S3StorageService {
  private readonly logger = new Logger(S3StorageService.name);
  private readonly s3Client: S3Client;
  private readonly bucketName: string;
  private readonly presignedUrlTtl: number;

  constructor(private readonly configService: ConfigService) {
    const endpoint = this.configService.get<string>('s3.endpoint');
    const forcePathStyle = this.configService.get<boolean>('s3.forcePathStyle');

    this.s3Client = new S3Client({
      region: this.configService.get<string>('s3.region')!,
      ...(endpoint ? { endpoint, forcePathStyle: forcePathStyle ?? true } : {}),
      credentials: {
        accessKeyId: this.configService.get<string>('s3.accessKeyId')!,
        secretAccessKey: this.configService.get<string>('s3.secretAccessKey')!,
      },
    });
    this.bucketName = this.configService.get<string>('s3.bucketName')!;
    this.presignedUrlTtl = this.configService.get<number>('s3.presignedUrlTtl', 300);
  }

  /**
   * Upload a PNG file to S3 with encryption.
   *
   * @returns The S3 object key for storage in the Design entity.
   */
  async uploadDesignPng(
    fileBuffer: Buffer,
    originalFilename: string,
    artistId: string,
  ): Promise<{ s3Key: string; bucket: string }> {
    const extension = originalFilename.split('.').pop() ?? 'png';
    const s3Key = `designs/${artistId}/${uuidv4()}.${extension}`;

    await this.s3Client.send(
      new PutObjectCommand({
        Bucket: this.bucketName,
        Key: s3Key,
        Body: fileBuffer,
        ContentType: 'image/png',
        ServerSideEncryption: 'AES256',
        // No public access
        ACL: undefined,
        Metadata: {
          'artist-id': artistId,
          'original-filename': originalFilename,
          'upload-timestamp': new Date().toISOString(),
        },
      }),
    );

    this.logger.log(`Uploaded design to s3://${this.bucketName}/${s3Key}`);

    return { s3Key, bucket: this.bucketName };
  }

  /**
   * Generate a time-limited presigned URL for secure client download.
   *
   * The URL expires after [presignedUrlTtl] seconds (default: 5 minutes).
   * HTTPS-only. No caching headers.
   */
  async generatePresignedUrl(s3Key: string): Promise<string> {
    const command = new GetObjectCommand({
      Bucket: this.bucketName,
      Key: s3Key,
      ResponseCacheControl: 'no-store, no-cache, must-revalidate',
      ResponseContentDisposition: 'inline', // Prevent browser download prompt
    });

    const url = await getSignedUrl(this.s3Client, command, {
      expiresIn: this.presignedUrlTtl,
    });

    return url;
  }

  /**
   * Delete a design asset from S3.
   */
  async deleteDesign(s3Key: string): Promise<void> {
    await this.s3Client.send(
      new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: s3Key,
      }),
    );

    this.logger.log(`Deleted design from s3://${this.bucketName}/${s3Key}`);
  }
}
