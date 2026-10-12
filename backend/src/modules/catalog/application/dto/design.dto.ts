import {
  IsString,
  IsEnum,
  IsOptional,
  IsArray,
  IsNumber,
  Min,
  Max,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DesignStyle } from '@prisma/client';

export class CreateDesignDto {
  @ApiProperty({ example: 'Serpentine Mandala' })
  @IsString()
  @MaxLength(200)
  title!: string;

  @ApiPropertyOptional({ example: 'Geometric serpent wrapping around forearm' })
  @IsString()
  @IsOptional()
  @MaxLength(2000)
  description?: string;

  @ApiProperty({ enum: DesignStyle, example: DesignStyle.CYBERSIGILISM })
  @IsEnum(DesignStyle)
  style!: DesignStyle;

  @ApiPropertyOptional({ example: ['forearm', 'calf'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  recommendedBodyParts?: string[];

  @ApiPropertyOptional({ example: 12.5, description: 'Estimated real-world width in cm' })
  @IsNumber()
  @IsOptional()
  @Min(0.5)
  @Max(100)
  estimatedWidthCm?: number;

  @ApiPropertyOptional({ example: 18.0, description: 'Estimated real-world height in cm' })
  @IsNumber()
  @IsOptional()
  @Min(0.5)
  @Max(100)
  estimatedHeightCm?: number;

  @ApiPropertyOptional({ example: ['mandala', 'geometric', 'serpent'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];
}

export class DesignResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiPropertyOptional()
  description?: string | null;

  @ApiProperty({ enum: DesignStyle })
  style!: DesignStyle;

  @ApiProperty()
  widthPx!: number;

  @ApiProperty()
  heightPx!: number;

  @ApiPropertyOptional()
  thumbnailUrl?: string | null;

  @ApiProperty()
  recommendedBodyParts!: string[];

  @ApiProperty()
  createdAt!: Date;
}

export class DesignListQueryDto {
  @ApiPropertyOptional({ enum: DesignStyle })
  @IsEnum(DesignStyle)
  @IsOptional()
  style?: DesignStyle;

  @ApiPropertyOptional({ example: 'mandala' })
  @IsString()
  @IsOptional()
  search?: string;

  @ApiPropertyOptional({ default: 20 })
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsNumber()
  @IsOptional()
  @Min(0)
  offset?: number;
}
