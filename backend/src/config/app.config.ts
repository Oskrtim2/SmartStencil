import { registerAs } from '@nestjs/config';

export const appConfig = registerAs('app', () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
}));

export const jwtConfig = registerAs('jwt', () => ({
  secret: process.env.JWT_SECRET!,
  expiration: process.env.JWT_EXPIRATION ?? '15m',
  refreshSecret: process.env.JWT_REFRESH_SECRET!,
  refreshExpiration: process.env.JWT_REFRESH_EXPIRATION ?? '7d',
}));

export const s3Config = registerAs('s3', () => ({
  region: process.env.AWS_REGION ?? 'us-east-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  bucketName: process.env.S3_BUCKET_NAME!,
  presignedUrlTtl: parseInt(process.env.S3_PRESIGNED_URL_TTL ?? '300', 10),
}));

export const shareConfig = registerAs('share', () => ({
  defaultTtl: parseInt(process.env.SHARE_TOKEN_DEFAULT_TTL ?? '86400', 10),
  maxUses: parseInt(process.env.SHARE_TOKEN_MAX_USES ?? '10', 10),
}));
