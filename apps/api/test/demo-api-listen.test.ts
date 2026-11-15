import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createServer, connect } from 'node:net';
import { networkInterfaces } from 'node:os';
import { resolve } from 'node:path';
import test from 'node:test';
import { demoConnection } from '../scripts/demo-guard';
import { demoEmail, demoId, demoPassword } from '../scripts/demo-seed';

test('demo API listens on loopback and does not expose its port on LAN interfaces', async () => {
  const reservation = createServer();
  reservation.listen(0, '127.0.0.1');
  await once(reservation, 'listening');
  const port = (reservation.address() as { port: number }).port;
  await new Promise<void>((ok, fail) => reservation.close(error => error ? fail(error) : ok()));
  const live = process.env.RUN_LOCAL_DEMO_HTTP_TEST === 'yes';
  if (live) demoConnection(process.env);
  const url = live ? process.env.DEMO_DATABASE_URL! : 'postgres://showtime_demo:showtime_demo@127.0.0.1:55439/showtime_demo';
  const child = spawn(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['run', 'start:demo'], {
    cwd: resolve(__dirname, '..'),
    env: { HOME: process.env.HOME, PATH: process.env.PATH, NODE_ENV: 'test', SEED_LOCAL_DEMO: 'yes', DEMO_DATABASE_URL: url, DATABASE_URL: url, PORT: String(port),
      REDIS_URL: 'redis://127.0.0.1:6379', MINIO_ENDPOINT: '127.0.0.1', MINIO_PORT: '9000', MINIO_USE_SSL: 'false', MINIO_ACCESS_KEY: 'demo', MINIO_SECRET_KEY: 'demo', MINIO_BUCKET: 'demo', BETTER_AUTH_SECRET: 'demo', STRIPE_MODE: 'test', STRIPE_SECRET_KEY: 'sk_test_demo' },
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: process.platform !== 'win32',
  });
  let output = '';
  let exited = false;
  child.once('exit', () => { exited = true; });
  child.stdout.on('data', data => { output += String(data); });
  child.stderr.on('data', data => { output += String(data); });
  try {
    let ready = false;
    for (let i = 0; i < 100; i++) {
      if (exited) throw new Error(`Demo API exited: ${output}`);
      try {
        const response = await fetch(`http://127.0.0.1:${port}/health`);
        if (response.ok) { ready = true; break; }
      } catch { /* Wait for the loopback server. */ }
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.ok(ready, `Demo API did not start: ${output}`);
    // This route needs both injected CommunityService and AuthService. It must
    // reject a missing token without attempting a database connection.
    const unauthorized = await fetch(`http://127.0.0.1:${port}/community/teams`);
    assert.equal(unauthorized.status, 403, `Expected authorization rejection: ${await unauthorized.text()}\n${output}`);
    if (live) {
      const base = `http://127.0.0.1:${port}`;
      const login = await fetch(`${base}/auth/login`, {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ identifier: demoEmail, password: demoPassword }),
      });
      assert.equal(login.status, 201, await login.clone().text());
      const credentials = await login.json() as { token: string; verified: boolean };
      assert.equal(credentials.verified, true);
      assert.ok(credentials.token);
      const get = async (path: string) => {
        const response = await fetch(`${base}${path}`, { headers: { authorization: `Bearer ${credentials.token}` } });
        assert.equal(response.status, 200, await response.clone().text());
        return response.json();
      };
      const session = await get('/auth/session') as { verified: boolean; user: { id: string } };
      assert.equal(session.verified, true);
      assert.equal(session.user.id, demoId(1, 1));
      const roster = await get(`/community/teams/${demoId(4, 1)}`) as { members: unknown[]; myRole: string };
      assert.equal(roster.myRole, 'captain');
      assert.equal(roster.members.length, 7);
      for (const [path, count] of [['teams', 3], ['challenges', 6], ['games', 2], ['notifications', 1]] as const) {
        const rows = await get(`/community/${path}`) as unknown[];
        assert.equal(rows.length, count, path);
      }
    }
    for (const address of Object.values(networkInterfaces()).flat().filter(item => item && item.family === 'IPv4' && !item.internal)) {
      const reachable = await new Promise<boolean>(resolve => {
        const socket = connect({ host: address!.address, port, timeout: 1000 });
        socket.once('connect', () => { socket.destroy(); resolve(true); });
        socket.once('error', () => resolve(false));
        socket.once('timeout', () => { socket.destroy(); resolve(false); });
      });
      assert.equal(reachable, false, `Demo API exposed on ${address!.address}`);
    }
  } finally {
    if (!exited) {
      const completion = once(child, 'exit');
      if (process.platform === 'win32') child.kill('SIGTERM');
      else if (child.pid) process.kill(-child.pid, 'SIGTERM');
      await completion;
    }
  }
});
