import { IsNumber, IsOptional, IsString, IsUUID, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateShareDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  designId!: string;

  @ApiPropertyOptional({ default: 1, example: 3, description: 'Maximum number of times this link can be used' })
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(100)
  maxUses?: number;

  @ApiPropertyOptional({ default: 86400, example: 3600, description: 'Time-to-live in seconds' })
  @IsNumber()
  @IsOptional()
  @Min(300)       // Minimum 5 minutes
  @Max(604800)    // Maximum 7 days
  ttlSeconds?: number;
}

export class ShareResponseDto {
  @ApiProperty({ description: 'Unique share token (UUID)' })
  token!: string;

  @ApiProperty({ description: 'QR code as data URL (PNG base64)' })
  qrCodeDataUrl!: string;

  @ApiProperty({ description: 'Token expiration timestamp' })
  expiresAt!: Date;

  @ApiProperty({ description: 'Maximum number of uses allowed' })
  maxUses!: number;

  @ApiProperty({ description: 'Deep link URL for the client app' })
  deepLink!: string;
}

export class SharedDesignResponseDto {
  @ApiProperty({ description: 'Time-limited presigned S3 URL for the design PNG' })
  presignedUrl!: string;

  @ApiProperty({ description: 'Design metadata for the AR engine' })
  metadata!: SharedDesignMetadataDto;
}

export class SharedDesignMetadataDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  style!: string;

  @ApiProperty()
  widthPx!: number;

  @ApiProperty()
  heightPx!: number;

  @ApiProperty()
  artistName!: string;

  @ApiPropertyOptional()
  recommendedBodyParts?: string[];

  @ApiPropertyOptional()
  estimatedWidthCm?: number;

  @ApiPropertyOptional()
  estimatedHeightCm?: number;
}
