import { Body, Controller, Get, Headers, Post, Req, UnauthorizedException } from '@nestjs/common';
import { AuthService, type AuthRegistration } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  private token(header?: string): string {
    const match = /^Bearer ([A-Za-z0-9_-]+)$/.exec(header ?? '');
    if (!match) throw new UnauthorizedException('Authentication required');
    return match[1];
  }

  @Post('register')
  async register(@Body() body: AuthRegistration, @Req() request: { ip: string }) {
    await this.auth.rateLimit(`register-ip:${request.ip}`, 20, 3600);
    return this.auth.register(body);
  }

  @Post('login')
  async login(@Body() body: { identifier?: string; password?: string }, @Req() request: { ip: string }) {
    await this.auth.rateLimit(`login-ip:${request.ip}`, 30, 900);
    return this.auth.login(body?.identifier ?? '', body?.password ?? '');
  }

  @Post('phone/resend')
  async resend(@Headers('authorization') authorization?: string) {
    await this.auth.resend(this.token(authorization));
    return { sent: true };
  }

  @Post('phone/verify')
  async verify(@Headers('authorization') authorization: string | undefined, @Body() body: { code?: string }) {
    const row = await this.auth.verify(this.token(authorization), body?.code ?? '');
    return { verified: true, user: { id: row.user_id, name: row.display_name, dateOfBirth: row.date_of_birth } };
  }

  @Get('session')
  async session(@Headers('authorization') authorization?: string) {
    const row = await this.auth.session(this.token(authorization), false);
    return { verified: row.phone_verified, phone: row.phone, user: { id: row.user_id, name: row.display_name, dateOfBirth: row.date_of_birth } };
  }

  @Post('logout')
  async logout(@Headers('authorization') authorization?: string) {
    await this.auth.logout(this.token(authorization));
    return { signedOut: true };
  }
}
