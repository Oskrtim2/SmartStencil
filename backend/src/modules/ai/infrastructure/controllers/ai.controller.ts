import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

import { AiStencilService } from '../../application/services/ai-stencil.service';
import { GenerateStencilDto, GenerateStencilResponseDto } from '../../application/dto/generate-stencil.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';

@ApiTags('ai')
@Controller('ai')
export class AiController {
  constructor(private readonly aiStencilService: AiStencilService) {}

  @Post('generate-stencil')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Generar stencil de tatuaje con IA optimizado para AR' })
  @ApiResponse({ status: 200, type: GenerateStencilResponseDto })
  async generateStencil(@Body() dto: GenerateStencilDto): Promise<GenerateStencilResponseDto> {
    return this.aiStencilService.generateStencil(dto);
  }
}
