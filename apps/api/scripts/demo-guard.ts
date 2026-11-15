import type { ClientConfig } from 'pg';

// Deliberately do not use DATABASE_URL, dotenv, URL normalization, or libpq defaults.
export function demoConnection(env: NodeJS.ProcessEnv): ClientConfig {
  if (!['development', 'test'].includes(env.NODE_ENV ?? '') || env.SEED_LOCAL_DEMO !== 'yes') {
    throw new Error('Demo seed requires NODE_ENV=development or test and SEED_LOCAL_DEMO=yes');
  }
  if (Object.keys(env).some(key => key.startsWith('PG'))) {
    throw new Error('Unset PG* environment variables before using the demo seed');
  }
  const url = env.DEMO_DATABASE_URL ?? '';
  const match = /^postgres(?:ql)?:\/\/showtime_demo:showtime_demo@(127\.0\.0\.1|\[::1\]):([0-9]{1,5})\/showtime_demo$/.exec(url);
  if (!match || match[0] !== url || Number(match[2]) < 1 || Number(match[2]) > 65535) {
    throw new Error('DEMO_DATABASE_URL must use the dedicated showtime_demo credentials and database on literal 127.0.0.1 or [::1], with an explicit port and no parameters');
  }
  return {
    host: match[1] === '[::1]' ? '::1' : match[1], port: Number(match[2]),
    database: 'showtime_demo', user: 'showtime_demo', password: 'showtime_demo', ssl: false,
    connectionTimeoutMillis: 3000,
  };
}

export function demoApiHost(env: NodeJS.ProcessEnv): '127.0.0.1' {
  demoConnection(env);
  if (env.DATABASE_URL !== env.DEMO_DATABASE_URL) {
    throw new Error('DATABASE_URL must explicitly equal DEMO_DATABASE_URL');
  }
  return '127.0.0.1';
}
