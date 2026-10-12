import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Req,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiConsumes, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../../common/guards/roles.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';
import { DesignService } from '../../application/services/design.service';
import { CreateDesignDto, DesignResponseDto, DesignListQueryDto } from '../../application/dto/design.dto';

@ApiTags('designs')
@ApiBearerAuth()
@Controller('designs')
@UseGuards(JwtAuthGuard, RolesGuard)
export class DesignController {
  constructor(private readonly designService: DesignService) {}

  @Post()
  @Roles(UserRole.ARTIST)
  @UseInterceptors(FileInterceptor('file', {
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
    fileFilter: (_req, file, cb) => {
      if (file.mimetype !== 'image/png') {
        cb(new Error('Only PNG files are accepted'), false);
      } else {
        cb(null, true);
      }
    },
  }))
  @ApiOperation({ summary: 'Upload a new tattoo design (Artist only)' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 201, type: DesignResponseDto })
  async createDesign(
    @Body() dto: CreateDesignDto,
    @UploadedFile() file: Express.Multer.File,
    @Req() req: any,
  ): Promise<DesignResponseDto> {
    // req.user is set by JwtStrategy.validate()
    return this.designService.createDesign(dto, file, req.user.artistProfileId);
  }

  @Get()
  @Roles(UserRole.ARTIST)
  @ApiOperation({ summary: 'List my designs with optional filters (Artist only)' })
  @ApiResponse({ status: 200, type: [DesignResponseDto] })
  async listDesigns(
    @Query() query: DesignListQueryDto,
    @Req() req: any,
  ): Promise<DesignResponseDto[]> {
    return this.designService.listByArtist(req.user.artistProfileId, query);
  }

  @Get(':id')
  @Roles(UserRole.ARTIST)
  @ApiOperation({ summary: 'Get a specific design by ID (Artist only)' })
  @ApiResponse({ status: 200, type: DesignResponseDto })
  @ApiResponse({ status: 404, description: 'Design not found' })
  async getDesign(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ): Promise<DesignResponseDto> {
    return this.designService.getDesign(id, req.user.artistProfileId);
  }

  @Post(':id/publish')
  @Roles(UserRole.ARTIST)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Publish a design to make it shareable (Artist only)' })
  @ApiResponse({ status: 204 })
  async publishDesign(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ): Promise<void> {
    return this.designService.publishDesign(id, req.user.artistProfileId);
  }

  @Delete(':id')
  @Roles(UserRole.ARTIST)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a design and its S3 asset (Artist only)' })
  @ApiResponse({ status: 204 })
  async deleteDesign(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ): Promise<void> {
    return this.designService.deleteDesign(id, req.user.artistProfileId);
  }
}
