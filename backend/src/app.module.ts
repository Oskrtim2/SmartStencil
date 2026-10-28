import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';

import { appConfig, jwtConfig, s3Config, shareConfig } from './config/app.config';
import { validationSchema } from './config/validation.schema';
import { IdentityModule } from './modules/identity/identity.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { SharingModule } from './modules/sharing/sharing.module';
import { AiModule } from './modules/ai/ai.module';
import { PrismaModule } from './common/prisma/prisma.module';
import { HealthModule } from './common/health/health.module';

@Module({
  imports: [
    // Configuration with validation
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, jwtConfig, s3Config, shareConfig],
      validationSchema,
      validationOptions: {
        abortEarly: true,
      },
    }),

    // Rate limiting
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,   // 1 second
        limit: 10,   // 10 requests per second
      },
      {
        name: 'medium',
        ttl: 60000,  // 1 minute
        limit: 100,  // 100 requests per minute
      },
    ]),

    // Database & Monitoring
    PrismaModule,
    HealthModule,

    // DDD Bounded Contexts
    IdentityModule,
    CatalogModule,
    SharingModule,
    AiModule,
  ],
})
export class AppModule {}
