import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { once } from 'node:events';
import { access, cp, mkdtemp, mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import test from 'node:test';
import { demoEmail, demoPassword } from '../scripts/demo-seed';
import { devDatabaseUrl } from '../scripts/dev-seed';

test('normal dev command emits Nest metadata, serves HTTP and reloads source changes', { timeout: 90000 }, async () => {
  const root = resolve(__dirname, '../../..');
  const temp = await mkdtemp(join(tmpdir(), 'showtime-dev-test-'));
  const api = join(temp, 'apps/api');
  let child: ReturnType<typeof spawn> | undefined;
  try {
    await mkdir(api, { recursive: true });
    await cp(join(root, 'package.json'), join(temp, 'package.json'));
    await symlink(join(root, 'node_modules'), join(temp, 'node_modules'), 'junction');
    const workspaceModules = join(root, 'apps/api/node_modules');
    if (await access(workspaceModules).then(() => true, () => false)) {
      await symlink(workspaceModules, join(api, 'node_modules'), 'junction');
    }
    for (const item of ['package.json', 'tsconfig.json', 'tsconfig.build.json', 'tsconfig.dev.json', 'src', 'scripts']) {
      await cp(join(root, 'apps/api', item), join(api, item), { recursive: true });
    }
    const health = join(api, 'src/health.controller.ts');
    const originalHealth = await readFile(health, 'utf8');
    // A prior build must never be served when the initial compilation fails.
    await mkdir(join(api, 'dist/dev'), { recursive: true });
    await writeFile(join(api, 'dist/dev/main.js'), "throw new Error('stale output was launched');\n");
    await writeFile(health, `${originalHealth}\nconst broken: string = 42;\n`);
    const reservation = createServer();
    reservation.listen(0, '127.0.0.1');
    await once(reservation, 'listening');
    const port = (reservation.address() as { port: number }).port;
    await new Promise<void>((ok, fail) => reservation.close(error => error ? fail(error) : ok()));
    const live = process.env.RUN_DEV_SEED_HTTP_TEST === 'yes';
    const url = live ? devDatabaseUrl(process.env) : 'postgres://showtime_demo:showtime_demo@127.0.0.1:1/showtime_demo';
    if (!live) await writeFile(join(api, 'scripts/seed-dev.ts'), "console.log('Test seed completed');\n");
    await writeFile(join(api, '.env'), [
      `DATABASE_URL=${url}`, 'REDIS_URL=redis://127.0.0.1:6379', 'MINIO_ENDPOINT=127.0.0.1',
      'MINIO_PORT=9000', 'MINIO_USE_SSL=false', 'MINIO_ACCESS_KEY=demo', 'MINIO_SECRET_KEY=demo',
      'MINIO_BUCKET=demo', 'BETTER_AUTH_SECRET=demo', 'STRIPE_MODE=test', 'STRIPE_SECRET_KEY=sk_test_demo',
      'TWILIO_ACCOUNT_SID=from-file', 'TWILIO_AUTH_TOKEN=from-file', 'TWILIO_VERIFY_SERVICE_SID=from-file',
    ].join('\n'));
    child = spawn(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['run', 'dev:api'], {
      cwd: temp, detached: process.platform !== 'win32', stdio: ['ignore', 'pipe', 'pipe'],
      env: { HOME: process.env.HOME, PATH: process.env.PATH, NODE_ENV: 'development', PORT: String(port), TWILIO_ACCOUNT_SID: 'from-shell' },
    });
    let output = '';
    child.stdout!.on('data', data => { output += String(data); });
    child.stderr!.on('data', data => { output += String(data); });
    const base = `http://127.0.0.1:${port}`;
    for (let i = 0; i < 250 && !output.includes('Development build failed'); i++) {
      assert.equal(child.exitCode, null, output);
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.match(output, /Development build failed/);
    assert.doesNotMatch(output, /Starting development API|stale output was launched/);
    await assert.rejects(() => fetch(`${base}/health`));
    await writeFile(health, originalHealth);
    const waitForHealth = async (service: string) => {
      for (let i = 0; i < 250; i++) {
        if (child!.exitCode !== null || child!.signalCode !== null) throw new Error(`Dev command exited: ${output}`);
        try {
          const response = await fetch(`${base}/health`);
          if (response.ok && (await response.json() as { service: string }).service === service) return;
        } catch { /* Wait for compilation or restart. */ }
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      throw new Error(`Dev API did not serve ${service}: ${output}`);
    };
    await waitForHealth('showtime-api');
    for (let i = 0; i < 50 && !output.includes(`Development API available at ${base}`); i++) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.ok(output.includes(`Development API available at ${base}`), output);
    // Load the actual emitted files, not tsx-transformed sources. Check both
    // controller -> service -> service and an unrelated nested provider path.
    const metadata = spawnSync(process.execPath, ['-e', `
      require('reflect-metadata');
      const {AuthController} = require('./dist/dev/modules/identity/auth.controller');
      const {AuthService} = require('./dist/dev/modules/identity/auth.service');
      const {CommunityController} = require('./dist/dev/modules/community/community.controller');
      const {CommunityService} = require('./dist/dev/modules/community/community.service');
      const {OperatorMetricsService} = require('./dist/dev/modules/analytics/operator-metrics.service');
      const {AnalyticsService} = require('./dist/dev/modules/analytics/analytics.service');
      const {PolicyGuard} = require('./dist/dev/modules/authz/policy.guard');
      const {Reflector} = require('@nestjs/core');
      const assert = require('node:assert/strict');
      for (const [target, dependency] of [[AuthController, AuthService], [CommunityController, CommunityService], [CommunityService, AuthService], [OperatorMetricsService, AnalyticsService], [PolicyGuard, Reflector]])
        assert.deepEqual(Reflect.getMetadata('design:paramtypes', target), [dependency]);
      require('./dist/dev/app.module');
      assert.equal(process.env.DATABASE_URL, process.env.EXPECTED_DATABASE_URL);
      assert.equal(process.env.TWILIO_ACCOUNT_SID, 'from-shell');
      assert.equal(process.env.TWILIO_AUTH_TOKEN, 'from-file');
    `], { cwd: api, encoding: 'utf8', env: { HOME: process.env.HOME, PATH: process.env.PATH, NODE_ENV: 'test', TWILIO_ACCOUNT_SID: 'from-shell', EXPECTED_DATABASE_URL: url } });
    assert.equal(metadata.status, 0, metadata.stderr);
    const unauthorized = await fetch(`${base}/community/teams`);
    assert.equal(unauthorized.status, 403, await unauthorized.clone().text());
    const noSession = await fetch(`${base}/auth/session`);
    assert.equal(noSession.status, 401, await noSession.clone().text());
    if (live) {
      const login = (password: string) => fetch(`${base}/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identifier: demoEmail, password }) });
      const bad = await login('incorrect');
      assert.equal(bad.status, 401, await bad.clone().text());
      const response = await login(demoPassword);
      assert.equal(response.status, 201, await response.clone().text());
      const credentials = await response.json() as { token: string; verified: boolean };
      assert.equal(credentials.verified, true);
      assert.ok(credentials.token);
      const headers = { authorization: `Bearer ${credentials.token}` };
      const session = await fetch(`${base}/auth/session`, { headers });
      assert.equal(session.status, 200, await session.clone().text());
      assert.equal((await session.json() as { user: { name: string } }).user.name, 'Demo Captain');
      const teams = await fetch(`${base}/community/teams`, { headers });
      assert.equal(teams.status, 200, await teams.clone().text());
      assert.ok(Array.isArray(await teams.json()));
      const invalid = await fetch(`${base}/community/teams`, { headers: { authorization: 'Bearer invalid' } });
      assert.equal(invalid.status, 401, await invalid.clone().text());
    }
    await writeFile(health, `${originalHealth}\nconst brokenAgain: string = 42;\n`);
    for (let i = 0; i < 250 && (output.match(/Development build failed/g) ?? []).length < 2; i++) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.equal((output.match(/Development build failed/g) ?? []).length, 2, output);
    await waitForHealth('showtime-api');
    await writeFile(health, originalHealth.replace('showtime-api', 'showtime-reloaded'));
    await waitForHealth('showtime-reloaded');
  } finally {
    if (child && child.exitCode === null && child.signalCode === null) {
      const completion = once(child, 'exit');
      if (process.platform === 'win32') child.kill('SIGTERM');
      else if (child.pid) process.kill(-child.pid, 'SIGTERM');
      await completion;
    }
    await rm(temp, { recursive: true, force: true });
  }
});
