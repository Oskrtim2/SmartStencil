import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,           // Strip unknown properties
      forbidNonWhitelisted: true, // Throw on unknown properties
      transform: true,           // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // CORS configuration (supports comma-separated origins or open by default for mobile/swagger)
  const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
    : true;

  app.enableCors({
    origin: corsOrigins,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // API prefix
  app.setGlobalPrefix('api/v1');

  // Swagger documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('InkSight API')
    .setDescription('AR Tattoo Preview Platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('health', 'Liveness and readiness health checks')
    .addTag('auth', 'Authentication & registration')
    .addTag('designs', 'Tattoo design catalog management')
    .addTag('sharing', 'Secure design sharing & QR generation')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  // Start server on 0.0.0.0 for cloud hosting compatibility
  const configService = app.get(ConfigService);
  const port = Number(process.env.PORT) || configService.get<number>('app.port', 3000);
  await app.listen(port, '0.0.0.0');

  console.log(`🖌️  InkSight API running on port ${port} (0.0.0.0)`);
  console.log(`📚 Swagger docs at http://0.0.0.0:${port}/api/docs`);
}

bootstrap();
