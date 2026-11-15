import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { demoApiHost } from './demo-guard';
import { setupOpenApi } from '../src/openapi';

async function main(): Promise<void> {
  const host = demoApiHost(process.env);
  // Never send SMS from this dedicated local process, even if an .env has keys.
  process.env.TWILIO_ACCOUNT_SID = '';
  process.env.TWILIO_AUTH_TOKEN = '';
  process.env.TWILIO_VERIFY_SERVICE_SID = '';
  const { AppModule } = await import('../src/app.module');
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  setupOpenApi(app);
  await app.listen(Number(process.env.PORT ?? 3000), host);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : 'Local demo API failed');
  process.exitCode = 1;
});
