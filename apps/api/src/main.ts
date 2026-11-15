import 'reflect-metadata';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupOpenApi } from './openapi';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  setupOpenApi(app);
  const port = Number(process.env.PORT ?? 3000);
  if (process.env.SHOWTIME_DEV_BIND_HOST) await app.listen(port, process.env.SHOWTIME_DEV_BIND_HOST);
  else await app.listen(port);
  if ((process.env.NODE_ENV ?? 'development') === 'development') {
    Logger.log(`Development API available at ${await app.getUrl()}`, 'Bootstrap');
  }
}

void bootstrap();
