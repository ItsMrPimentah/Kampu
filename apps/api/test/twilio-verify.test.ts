import assert from 'node:assert/strict';
import test from 'node:test';
import { TwilioVerify } from '../src/modules/identity/twilio-verify';

test('sends and checks SMS verification through the Twilio Verify service', async () => {
  const calls: Array<{ url: string; init?: RequestInit }> = [];
  const request: typeof fetch = async (input, init) => {
    calls.push({ url: String(input), init });
    return new Response(JSON.stringify({ status: calls.length === 1 ? 'pending' : 'approved' }), { status: 200 });
  };
  const verifier = new TwilioVerify('ACtest', 'secret', 'VAtest', request);
  await verifier.send('+351912345678');
  assert.equal(await verifier.check('+351912345678', '123456'), true);
  assert.match(calls[0].url, /\/Services\/VAtest\/Verifications$/);
  assert.equal((calls[0].init?.body as URLSearchParams).get('Channel'), 'sms');
  assert.equal((calls[0].init?.body as URLSearchParams).get('To'), '+351912345678');
  assert.match(calls[1].url, /\/VerificationCheck$/);
  assert.equal((calls[1].init?.body as URLSearchParams).get('Code'), '123456');
  assert.equal((calls[0].init?.headers as Record<string, string>).Authorization, `Basic ${Buffer.from('ACtest:secret').toString('base64')}`);
});

test('rejects provider failures and does not approve pending checks', async () => {
  const pending = new TwilioVerify('ACtest', 'secret', 'VAtest', async () => new Response('{"status":"pending"}'));
  assert.equal(await pending.check('+351912345678', '123456'), false);
  const unavailable = new TwilioVerify('ACtest', 'secret', 'VAtest', async () => new Response('', { status: 500 }));
  await assert.rejects(() => unavailable.send('+351912345678'));
});
