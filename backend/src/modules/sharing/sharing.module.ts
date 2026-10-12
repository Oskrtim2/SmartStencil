import { Module } from '@nestjs/common';

import { SharingService } from './application/services/sharing.service';
import { SharingController } from './infrastructure/controllers/sharing.controller';
import { CatalogModule } from '../catalog/catalog.module';

@Module({
  imports: [CatalogModule], // Needs DesignRepository + S3StorageService
  controllers: [SharingController],
  providers: [SharingService],
})
export class SharingModule {}
