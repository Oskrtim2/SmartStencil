import * as Joi from 'joi';

/**
 * Environment variable validation schema.
 *
 * All required env vars are validated at startup. The app will fail fast
 * with a descriptive error if any are missing or malformed.
 */
export const validationSchema = Joi.object({
  // Server
  NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
  PORT: Joi.number().default(3000),

  // Database
  DATABASE_URL: Joi.string().uri().required(),

  // JWT
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRATION: Joi.string().default('15m'),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_EXPIRATION: Joi.string().default('7d'),

  // AWS S3
  AWS_REGION: Joi.string().default('us-east-1'),
  AWS_ACCESS_KEY_ID: Joi.string().required(),
  AWS_SECRET_ACCESS_KEY: Joi.string().required(),
  S3_BUCKET_NAME: Joi.string().required(),
  S3_PRESIGNED_URL_TTL: Joi.number().default(300), // 5 minutes

  // Share tokens
  SHARE_TOKEN_DEFAULT_TTL: Joi.number().default(86400), // 24 hours
  SHARE_TOKEN_MAX_USES: Joi.number().default(10),
});
