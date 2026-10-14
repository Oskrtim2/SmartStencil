import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GenerateStencilDto {
  @ApiProperty({
    example: 'Dragón oriental con flores de cerezo estilo líneas finas',
    description: 'Descripción conceptual del tatuaje para la IA',
  })
  @IsString()
  @IsNotEmpty({ message: 'El prompt o descripción es obligatorio' })
  @MaxLength(300, { message: 'El prompt no puede exceder los 300 caracteres' })
  prompt!: string;

  @ApiPropertyOptional({
    example: 'FINE_LINE',
    description: 'Estilo visual del tatuaje: FINE_LINE, BLACKWORK, GEOMETRIC, NEOTRIBAL, JAPANESE, MINIMALIST',
  })
  @IsString()
  @IsOptional()
  style?: string;

  @ApiPropertyOptional({
    example: 'forearm',
    description: 'Zona del cuerpo anatómica sugerida: forearm, wrist, shoulder, calf, chest, back',
  })
  @IsString()
  @IsOptional()
  placement?: string;

  @ApiPropertyOptional({
    example: 'medium',
    description: 'Nivel de detalle del trazo: minimal, medium, intricate',
  })
  @IsString()
  @IsOptional()
  detailLevel?: string;
}

export class GenerateStencilResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  prompt!: string;

  @ApiProperty()
  style!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ description: 'Data URL del stencil PNG con fondo transparente listo para AR' })
  stencilDataUrl!: string;

  @ApiProperty({ description: 'Recomendación anatómica generada por IA para la zona' })
  placementAdvice!: string;

  @ApiProperty({ description: 'Curvatura cilíndrica sugerida para el mapper AR' })
  suggestedCurvatureFactor!: number;

  @ApiProperty({ description: 'Tamaño sugerido en cm (ancho x alto)' })
  estimatedSizeCm!: { width: number; height: number };

  @ApiProperty()
  createdAt!: string;
}
