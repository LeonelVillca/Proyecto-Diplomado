import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const configService = app.get(ConfigService);

  app.enableCors({
    origin: true, // en desarrollo; restringir en producción
    credentials: true,
  });
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useStaticAssets(join(process.cwd(), 'storage', 'publico'), {
    prefix: '/publico/',
  });

  const port = configService.get<number>('PORT', 3000);
  await app.listen(port, '0.0.0.0');

  Logger.log(`Servidor corriendo en http://0.0.0.0:${port}`, 'Bootstrap');
  Logger.log(`🚀 API corriendo en http://localhost:${port}/api/v1`, 'Bootstrap');
}

void bootstrap();
