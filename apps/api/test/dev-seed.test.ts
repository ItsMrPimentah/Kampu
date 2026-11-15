import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import test from 'node:test';
import { devDatabaseUrl } from '../scripts/dev-seed';

const local = 'postgres://showtime:showtime@localhost:5432/showtime';

test('development seed accepts only the configured local Compose database', () => {
  assert.equal(devDatabaseUrl({ NODE_ENV: 'development', DATABASE_URL: local }), local);
  for (const env of [
    { NODE_ENV: 'production', DATABASE_URL: local },
    { NODE_ENV: 'test', DATABASE_URL: local },
    { NODE_ENV: 'development', DATABASE_URL: 'postgres://showtime:showtime@example.com:5432/showtime' },
    { NODE_ENV: 'development', DATABASE_URL: `${local}?host=example.com` },
    { NODE_ENV: 'development', DATABASE_URL: `${local}\n` },
    { NODE_ENV: 'development', DATABASE_URL: local, PGHOST: 'example.com' },
  ]) assert.throws(() => devDatabaseUrl(env));
});

test('dev command stops before starting the API when seeding is rejected', () => {
  const result = spawnSync(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['run', 'dev:api'], {
    cwd: resolve(__dirname, '../../..'), encoding: 'utf8', timeout: 15000,
    env: { HOME: process.env.HOME, PATH: process.env.PATH, NODE_ENV: 'production', DATABASE_URL: local },
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Development seed requires NODE_ENV=development/);
  assert.doesNotMatch(result.stdout, /Starting development API/);
});
