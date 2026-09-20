import { INestApplication, ValidationPipe } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import request from 'supertest';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AUTH_RATE_LIMITS } from '../../core/config/security.config';

describe('Límites HTTP reales de autenticación', () => {
  let app: INestApplication;
  const service = { login: jest.fn(() => ({ token: 'test' })), verificarPinRecuperacion: jest.fn(() => ({ valido: true })) };
  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot(AUTH_RATE_LIMITS)], controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: service }, { provide: APP_GUARD, useClass: ThrottlerGuard }],
    }).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
  });
  afterAll(async () => { await app?.close(); });
  it('bloquea el intento 11 de login (no espera al límite global 100)', async () => {
    for (let i = 0; i < 10; i++) await request(app.getHttpServer()).post('/auth/login').send({ correo: 'test@example.test', password: 'test-password' }).expect(200);
    await request(app.getHttpServer()).post('/auth/login').send({ correo: 'test@example.test', password: 'test-password' }).expect(429);
    expect(service.login).toHaveBeenCalledTimes(10);
  });
  it('rechaza un PIN mal formado antes de consultar la cuenta', async () => {
    await request(app.getHttpServer()).post('/auth/verificar-pin-recuperacion').send({ correo: 'test@example.test', pin: 'abc' }).expect(400);
    expect(service.verificarPinRecuperacion).not.toHaveBeenCalled();
  });
});
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
