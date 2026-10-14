import { Module } from '@nestjs/common';

import { AiController } from './infrastructure/controllers/ai.controller';
import { AiStencilService } from './application/services/ai-stencil.service';
import { IdentityModule } from '../identity/identity.module';

@Module({
  imports: [IdentityModule],
  controllers: [AiController],
  providers: [AiStencilService],
  exports: [AiStencilService],
})
export class AiModule {}
