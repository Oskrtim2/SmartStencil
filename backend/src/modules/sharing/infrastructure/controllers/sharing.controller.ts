import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Body,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../../common/guards/roles.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';
import { SharingService } from '../../application/services/sharing.service';
import {
  CreateShareDto,
  ShareResponseDto,
  SharedDesignResponseDto,
} from '../../application/dto/sharing.dto';

@ApiTags('sharing')
@Controller('sharing')
export class SharingController {
  constructor(private readonly sharingService: SharingService) {}

  /**
   * Create a share token + QR code for a design.
   * Artist-only endpoint.
   */
  @Post('create')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ARTIST)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate a share token and QR code for a design (Artist only)' })
  @ApiResponse({ status: 201, type: ShareResponseDto })
  async createShareToken(
    @Body() dto: CreateShareDto,
    @Req() req: any,
  ): Promise<ShareResponseDto> {
    return this.sharingService.createShareToken(dto, req.user.artistProfileId);
  }

  /**
   * Consume a share token to get the presigned design URL.
   *
   * This is the PUBLIC endpoint that clients call after scanning a QR code.
   * No authentication required — the token itself is the credential.
   */
  @Get('consume/:token')
  @ApiOperation({
    summary: 'Consume a share token to access a design (Public — used by clients after QR scan)',
  })
  @ApiResponse({ status: 200, type: SharedDesignResponseDto })
  @ApiResponse({ status: 404, description: 'Token not found' })
  @ApiResponse({ status: 410, description: 'Token expired, revoked, or exhausted' })
  async consumeToken(
    @Param('token') token: string,
  ): Promise<SharedDesignResponseDto> {
    return this.sharingService.consumeShareToken(token);
  }

  /**
   * Revoke a share token. Artist-only endpoint.
   */
  @Delete(':id/revoke')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ARTIST)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Revoke a share token (Artist only)' })
  @ApiResponse({ status: 204 })
  async revokeToken(
    @Param('id') id: string,
    @Req() req: any,
  ): Promise<void> {
    return this.sharingService.revokeToken(id, req.user.artistProfileId);
  }
}
