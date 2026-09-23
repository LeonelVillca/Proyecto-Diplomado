import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import helmet from 'helmet';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module';
import { originAllowed } from './core/config/security.config';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const configService = app.get(ConfigService);

  // VUL-012: Validar que JWT_SECRET esté configurado antes de arrancar
  const jwtSecret = configService.get<string>('JWT_SECRET');
  if (!jwtSecret || jwtSecret.length < 32) {
    throw new Error(
      'FATAL: JWT_SECRET no está configurado o es demasiado corto (mínimo 32 caracteres). ' +
      'Configure la variable de entorno JWT_SECRET antes de arrancar el servidor.',
    );
  }

  // VUL-018: Helmet — headers de seguridad HTTP
  app.use(helmet());

  // VUL-002: CORS restringido a orígenes conocidos
  app.enableCors({
    origin: (origin, callback) => {
      // Permitir peticiones sin origen (apps móviles, Postman en desarrollo) o desde cualquier localhost (Flutter Web)
      if (originAllowed(origin)) {
        callback(null, true);
      } else {
        callback(null, false);
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  app.setGlobalPrefix('api/v1');

  const swaggerConfig = new DocumentBuilder()
    .setTitle('API Restaurantes')
    .setDescription(
      'Documentación interactiva de la API para la gestión de restaurantes, menús, reservas, reseñas y usuarios.',
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Ingrese únicamente el token JWT, sin el prefijo Bearer.',
      },
      'access-token',
    )
    .addServer('/api/v1', 'API v1')
    .build();
  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, swaggerDocument, {
    jsonDocumentUrl: 'docs-json',
    customSiteTitle: 'API Restaurantes | Swagger',
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

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
  Logger.log(`📚 Swagger disponible en http://localhost:${port}/docs`, 'Bootstrap');
}

void bootstrap();
