import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { SolicitudController } from './solicitud.controller';
import { SolicitudService } from './solicitud.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';

describe('Confirmación HTTP de solicitudes', () => {
  let app: INestApplication;
  const service = {
    verificarCorreo: jest.fn(async () => ({ mensaje: 'ok' })),
    crear: jest.fn(async () => ({ id: 5, usuario: { correo: 'privado@example.test' } })),
  };
  const token = 'a'.repeat(64);

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [SolicitudController],
      providers: [
        { provide: SolicitudService, useValue: service },
      ],
    })
      .overrideGuard(JwtAuthGuard).useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard).useValue({ canActivate: () => true })
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterAll(async () => { if (app) await app.close(); });

  it('abrir el enlace no consume el token (evita verificaciones por prelectura de correos)', async () => {
    await request(app.getHttpServer()).get(`/api/v1/solicitud/verificar-correo?token=${token}`)
      .expect(200)
      .expect('Cache-Control', 'no-store');
    expect(service.verificarCorreo).not.toHaveBeenCalled();
  });

  it('solo el POST explícito confirma el correo', async () => {
    await request(app.getHttpServer()).post('/api/v1/solicitud/confirmar-correo')
      .type('form').send({ token }).expect(200);
    expect(service.verificarCorreo).toHaveBeenCalledWith(token);
  });

  it('rechaza enlaces malformados antes de mostrar el formulario', async () => {
    await request(app.getHttpServer()).get('/api/v1/solicitud/verificar-correo?token=bad').expect(400);
  });

  it('la respuesta pública de alta no expone usuario ni detalles internos', async () => {
    const response = await request(app.getHttpServer()).post('/api/v1/solicitud')
      .field('correoUsuario', 'u@example.test')
      .attach('documentoNit', Buffer.from('dummy'), { filename: 'nit.pdf', contentType: 'application/pdf' })
      .attach('documentoCi', Buffer.from('dummy'), { filename: 'ci.pdf', contentType: 'application/pdf' })
      .expect(201);
    expect(response.body).toEqual({ mensaje: expect.any(String) });
    expect(service.crear).toHaveBeenCalled();
  });
});
