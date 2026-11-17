export interface PhoneVerifier {
  send(phone: string): Promise<void>;
  check(phone: string, code: string): Promise<boolean>;
}

/** Twilio Verify owns OTP generation, expiry and attempt limits. */
export class TwilioVerify implements PhoneVerifier {
  constructor(
    private readonly accountSid: string,
    private readonly authToken: string,
    private readonly serviceSid: string,
    private readonly request: typeof fetch = fetch,
  ) {}

  private async post(resource: string, fields: Record<string, string>): Promise<{ status?: string }> {
    if (!this.accountSid || !this.authToken || !this.serviceSid) throw new Error('Twilio Verify is not configured');
    const response = await this.request(`https://verify.twilio.com/v2/Services/${encodeURIComponent(this.serviceSid)}/${resource}`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams(fields),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error('Phone verification provider unavailable or request rejected');
    return await response.json() as { status?: string };
  }

  async send(phone: string): Promise<void> {
    await this.post('Verifications', { To: phone, Channel: 'sms' });
  }

  async check(phone: string, code: string): Promise<boolean> {
    return (await this.post('VerificationCheck', { To: phone, Code: code })).status === 'approved';
  }
}
