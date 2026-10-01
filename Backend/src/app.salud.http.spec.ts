import { INestApplication } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuditInterceptor } from './core/security/audit.interceptor';

describe('GET /api/v1/salud', () => {
  let app: INestApplication;
  const query = jest.fn();

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }])],
      controllers: [AppController],
      providers: [
        AppService,
        { provide: DataSource, useValue: { query } },
        { provide: APP_GUARD, useClass: ThrottlerGuard },
        { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  beforeEach(() => query.mockReset());
  afterAll(async () => {
    await app.close();
  });

  it('responde 200 sin JWT tras consultar la base en cada petición', async () => {
    query.mockResolvedValue([{ '?column?': 1 }]);
    for (let i = 0; i < 2; i++) {
      await request(app.getHttpServer())
        .get('/api/v1/salud')
        .expect(200)
        .expect({ estado: 'ok', baseDatos: 'conectada' });
    }
    expect(query).toHaveBeenCalledTimes(2);
    expect(query).toHaveBeenNthCalledWith(1, 'SELECT 1');
    expect(query).toHaveBeenNthCalledWith(2, 'SELECT 1');
  });

  it('responde 503 sin exponer detalles si falla el DataSource', async () => {
    query.mockRejectedValue(
      new Error('host=privado user=secreto password=secreto'),
    );
    await request(app.getHttpServer())
      .get('/api/v1/salud')
      .expect(503)
      .expect({ estado: 'error', baseDatos: 'no disponible' });
    expect(query).toHaveBeenCalledWith('SELECT 1');
  });

  it('no registra una segunda ruta con el prefijo duplicado', async () => {
    await request(app.getHttpServer()).get('/api/v1/api/v1/salud').expect(404);
    expect(query).not.toHaveBeenCalled();
  });
});
