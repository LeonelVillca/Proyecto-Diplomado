import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppController } from '../../src/app.controller';
import { AppService } from '../../src/app.service';

// El ejecutor E3 usa un clúster local exclusivo y no carga .env.
describe('Salud con PostgreSQL real (E3)', () => {
  let app: INestApplication;
  let db: DataSource;

  beforeAll(async () => {
    if (
      process.env.E3_INTEGRATION_TEST !== '1' ||
      process.env.DB_HOST !== '127.0.0.1' ||
      process.env.DB_PORT !== '55433' ||
      process.env.DB_NAME !== 'mesa_chapaca_e3_test'
    ) {
      throw new Error('Ejecutar únicamente con npm run test:e3.');
    }
    db = new DataSource({
      type: 'postgres',
      host: '127.0.0.1',
      port: 55433,
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: 'mesa_chapaca_e3_test',
      synchronize: false,
    });
    await db.initialize();
    const module = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService, { provide: DataSource, useValue: db }],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterAll(async () => {
    if (app) await app.close();
    if (db?.isInitialized) await db.destroy();
  });

  it('responde 200 sin JWT al ejecutar SELECT 1 en PostgreSQL real', async () => {
    const query = jest.spyOn(db, 'query');
    try {
      await request(app.getHttpServer())
        .get('/api/v1/salud')
        .expect(200)
        .expect({ estado: 'ok', baseDatos: 'conectada' });
      expect(query).toHaveBeenCalledWith('SELECT 1');
    } finally {
      query.mockRestore();
    }
  });
});
