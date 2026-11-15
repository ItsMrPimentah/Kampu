export type AppEnvironment = 'development' | 'test' | 'production';

export interface AppConfig {
  nodeEnv: AppEnvironment;
  port: number;
  databaseUrl: string;
  redisUrl: string;
  minio: {
    endpoint: string;
    port: number;
    useSsl: boolean;
    accessKey: string;
    secretKey: string;
    bucket: string;
  };
  betterAuthSecret: string;
  stripeMode: 'test' | 'live';
  stripeSecretKey: string;
  pilotRegions: string[];
  pilotVenuePartner: string;
  featureFlags: Record<string, boolean>;
}

export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigurationError';
  }
}

function required(values: NodeJS.ProcessEnv, key: string): string {
  const value = values[key]?.trim();
  if (!value) throw new ConfigurationError(`Missing required environment variable: ${key}`);
  return value;
}

function positiveInt(value: string, key: string): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ConfigurationError(`${key} must be a positive integer`);
  }
  return parsed;
}

function booleanValue(value: string, key: string): boolean {
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new ConfigurationError(`${key} must be true or false`);
}

export function loadConfig(values: NodeJS.ProcessEnv = process.env): AppConfig {
  const nodeEnv = (values.NODE_ENV ?? 'development') as AppEnvironment;
  if (!['development', 'test', 'production'].includes(nodeEnv)) {
    throw new ConfigurationError('NODE_ENV must be development, test, or production');
  }

  const stripeMode = (values.STRIPE_MODE ?? 'test') as 'test' | 'live';
  if (!['test', 'live'].includes(stripeMode)) {
    throw new ConfigurationError('STRIPE_MODE must be test or live');
  }
  const stripeSecretKey = required(values, 'STRIPE_SECRET_KEY');
  if (stripeMode === 'test' && !stripeSecretKey.startsWith('sk_test_')) {
    throw new ConfigurationError('STRIPE_SECRET_KEY must be a test key when STRIPE_MODE=test');
  }
  if (stripeMode === 'live' && nodeEnv !== 'production') {
    throw new ConfigurationError('Live Stripe mode is only allowed in production');
  }

  return {
    nodeEnv,
    port: positiveInt(values.PORT ?? '3000', 'PORT'),
    databaseUrl: required(values, 'DATABASE_URL'),
    redisUrl: required(values, 'REDIS_URL'),
    minio: {
      endpoint: required(values, 'MINIO_ENDPOINT'),
      port: positiveInt(values.MINIO_PORT ?? '9000', 'MINIO_PORT'),
      useSsl: booleanValue(values.MINIO_USE_SSL ?? 'false', 'MINIO_USE_SSL'),
      accessKey: required(values, 'MINIO_ACCESS_KEY'),
      secretKey: required(values, 'MINIO_SECRET_KEY'),
      bucket: required(values, 'MINIO_BUCKET'),
    },
    betterAuthSecret: required(values, 'BETTER_AUTH_SECRET'),
    stripeMode,
    stripeSecretKey,
    pilotRegions: (values.PILOT_REGIONS ?? 'Lisbon,Setúbal')
      .split(',')
      .map((region) => region.trim())
      .filter(Boolean),
    pilotVenuePartner: values.PILOT_VENUE_PARTNER?.trim() || 'PlayArena',
    featureFlags: {
      nativeBooking: booleanValue(values.FEATURE_NATIVE_BOOKING ?? 'false', 'FEATURE_NATIVE_BOOKING'),
      payments: booleanValue(values.FEATURE_PAYMENTS ?? 'false', 'FEATURE_PAYMENTS'),
      advertising: booleanValue(values.FEATURE_ADVERTISING ?? 'false', 'FEATURE_ADVERTISING'),
    },
  };
}

// Nest publishes the object returned by validate to process.env. Preserve the
// original environment keys for services that consume them directly, while
// retaining the parsed configuration for ConfigService consumers.
export function validateEnvironment(values: NodeJS.ProcessEnv) {
  return { ...values, ...loadConfig(values) };
}
