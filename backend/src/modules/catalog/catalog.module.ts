import { Module } from '@nestjs/common';

import { DesignService } from './application/services/design.service';
import { S3StorageService } from './application/services/s3-storage.service';
import { DesignController } from './infrastructure/controllers/design.controller';
import { DesignRepository } from './infrastructure/repositories/design.repository';

@Module({
  controllers: [DesignController],
  providers: [DesignService, S3StorageService, DesignRepository],
  exports: [DesignService, S3StorageService, DesignRepository],
})
export class CatalogModule {}
