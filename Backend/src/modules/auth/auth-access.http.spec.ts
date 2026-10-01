import { INestApplication } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { PassportModule } from '@nestjs/passport';
import { DataSource } from 'typeorm';
import request from 'supertest';
import { UsuariosController } from '../usuarios/usuarios.controller';
import { UsuariosService } from '../usuarios/usuarios.service';
import { CuentasAuthService } from '../cuentas-auth/cuentas-auth.service';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { JwtStrategy } from './jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { ConfigService } from '@nestjs/config';

describe('Acceso HTTP a GET /api/v1/usuarios', () => {
  let app: INestApplication;
  let jwt: JwtService;
  const secret = 'a'.repeat(64);
  const usuario = { id: 1, estado: 'activo', correo: 'admin@example.test' };
  const cuenta = { estado: true, sessionVersion: 0, usuario };
  let roles: string[];
  const listarTodos = jest.fn(async () => [usuario]);
  const buscarPorUsuario = jest.fn(async () => cuenta);

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        PassportModule,
        JwtModule.register({
          secret,
          signOptions: { expiresIn: '1h', algorithm: 'HS256', issuer: 'mesa-chapaca', audience: 'mesa-chapaca-app' },
        }),
      ],
      controllers: [UsuariosController],
      providers: [
        JwtStrategy,
        JwtAuthGuard,
        RolesGuard,
        { provide: ConfigService, useValue: new ConfigService({ JWT_SECRET: secret }) },
        { provide: UsuariosService, useValue: { listarTodos } },
        { provide: CuentasAuthService, useValue: { buscarPorUsuario } },
        {
          provide: DataSource,
          useValue: {
            getRepository: (entity: unknown) => {
              if (entity !== UsuarioRol) throw new Error('Repositorio inesperado');
              return { find: async () => roles.map((nombre) => ({ rol: { nombre } })) };
            },
          },
        },
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
    jwt = module.get(JwtService);
  });

  beforeEach(() => {
    roles = ['admin_restaurante'];
    listarTodos.mockClear();
    buscarPorUsuario.mockClear();
  });

  afterAll(async () => { await app?.close(); });

  function token(options: { expiresIn?: number; secret?: string } = {}) {
    return jwt.sign(
      { sub: usuario.id, correo: usuario.correo, sv: 0, sessionStartedAt: Math.floor(Date.now() / 1000) - 30 },
      options,
    );
  }

  it('responde 401 sin Bearer token', async () => {
    await request(app.getHttpServer()).get('/api/v1/usuarios').expect(401);
    expect(listarTodos).not.toHaveBeenCalled();
  });

  it('responde 401 con firma inválida', async () => {
    await request(app.getHttpServer()).get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${token({ secret: 'b'.repeat(64) })}`).expect(401);
    expect(listarTodos).not.toHaveBeenCalled();
  });

  it('responde 401 con JWT vencido', async () => {
    await request(app.getHttpServer()).get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${token({ expiresIn: -1 })}`).expect(401);
    expect(listarTodos).not.toHaveBeenCalled();
  });

  it('responde 403 al admin_restaurante autenticado', async () => {
    await request(app.getHttpServer()).get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${token()}`).expect(403);
    expect(buscarPorUsuario).toHaveBeenCalledWith(usuario.id);
    expect(listarTodos).not.toHaveBeenCalled();
  });

  it('permite al admin_sistema autenticado', async () => {
    roles = ['admin_sistema'];
    await request(app.getHttpServer()).get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${token()}`).expect(200);
    expect(listarTodos).toHaveBeenCalledTimes(1);
  });
});
