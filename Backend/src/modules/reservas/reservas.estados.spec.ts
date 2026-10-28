import {
  BadRequestException,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { OwnershipGuard } from '../../core/guards/ownership.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { Mesa } from '../mesa/mesa.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { UsuarioRestauranteAccesoService } from '../usuario-restaurante/usuario-restaurante-acceso.service';
import { ESTADO_RESERVA } from './dto/actualizar-reserva.dto';
import { ReservasController } from './reservas.controller';
import { ReservasService } from './reservas.service';

function preparar(estado = 'pendiente') {
  const almacenada = {
    id: 9,
    estado,
    usuario: { id: 26 },
    mesa: {
      id: 2,
      estado: 'libre',
      capacidad: 4,
      restaurante: { id: 3, zonaHoraria: 'America/La_Paz' },
    },
    fecha: '2026-11-20',
    hora: '16:00',
    duracionMinutos: 60,
    numeroPersonas: 2,
    comentarios: 'Reserva ficticia',
  };
  const copiaTrabajo = structuredClone(almacenada);
  const consulta = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getCount: jest.fn().mockResolvedValue(0),
  };
  const mesas = { findOne: jest.fn().mockResolvedValue(copiaTrabajo.mesa) };
  const reservas = {
    findOne: jest.fn().mockResolvedValue(structuredClone(almacenada)),
    createQueryBuilder: jest.fn().mockReturnValue(consulta),
  };
  const manager = {
    query: jest.fn().mockResolvedValue([]),
    getRepository: jest.fn((entity) => (entity === Mesa ? mesas : reservas)),
    findOne: jest.fn().mockResolvedValue(copiaTrabajo),
    save: jest.fn(async (_entity, value) => {
      Object.assign(almacenada, structuredClone(value));
      return value;
    }),
  };
  const transaction = jest.fn(async (callback) => callback(manager));
  const repo = { ...reservas, manager: { transaction } };
  const gateway = {
    emitActualizacionReserva: jest.fn().mockResolvedValue(undefined),
  };
  const notificaciones = {
    crearPorCambioDeReserva: jest.fn().mockResolvedValue({ id: 10 }),
    enviarPush: jest.fn().mockResolvedValue(undefined),
  };
  const service = new ReservasService(
    repo as any,
    {} as any,
    mesas as any,
    {
      find: jest
        .fn()
        .mockResolvedValue([{ horaInicio: '12:00', horaFin: '23:00' }]),
    } as any,
    { findOne: jest.fn().mockResolvedValue(null) } as any,
    gateway as any,
    notificaciones as any,
  );
  return {
    service,
    almacenada,
    copiaTrabajo,
    repo,
    manager,
    transaction,
    gateway,
    notificaciones,
  };
}

// RF-12: confirmar/rechazar pendientes son las acciones actuales del panel.
// RF-06 y la finalización automática mantienen sus flujos independientes.
describe('RF-12: cambios de estado administrativos', () => {
  it.each(['confirmada', 'rechazada'])(
    'permite pendiente -> %s y comunica el cambio',
    async (estado) => {
      const ctx = preparar();
      await expect(
        ctx.service.actualizar(9, { estado }),
      ).resolves.toMatchObject({ id: 9, estado });
      expect(ctx.almacenada.estado).toBe(estado);
      expect(ctx.transaction).toHaveBeenCalledTimes(1);
      expect(ctx.manager.save).toHaveBeenCalledTimes(1);
      expect(ctx.manager.query).toHaveBeenCalledWith(
        'SELECT id_reserva FROM reservas WHERE id_reserva = $1 FOR UPDATE',
        [9],
      );
      expect(ctx.notificaciones.crearPorCambioDeReserva).toHaveBeenCalledTimes(
        1,
      );
      expect(ctx.gateway.emitActualizacionReserva).toHaveBeenCalledWith(
        9,
        estado,
        3,
        26,
      );
    },
  );

  const rechazadas = ESTADO_RESERVA.flatMap((anterior) =>
    ESTADO_RESERVA.filter(
      (nuevo) =>
        nuevo !== anterior &&
        !(
          anterior === 'pendiente' &&
          ['confirmada', 'rechazada'].includes(nuevo)
        ),
    ).map((nuevo) => [anterior, nuevo]),
  );
  it.each(rechazadas)(
    'rechaza %s -> %s antes de alterar o guardar la reserva',
    async (anterior, nuevo) => {
      const ctx = preparar(anterior);
      const original = structuredClone(ctx.almacenada);
      await expect(
        ctx.service.actualizar(9, {
          estado: nuevo,
          comentarios: 'No debe guardarse',
          numeroPersonas: 3,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(ctx.almacenada).toEqual(original);
      expect(ctx.copiaTrabajo).toEqual(original);
      expect(ctx.manager.save).not.toHaveBeenCalled();
      expect(ctx.notificaciones.crearPorCambioDeReserva).not.toHaveBeenCalled();
      expect(ctx.notificaciones.enviarPush).not.toHaveBeenCalled();
      expect(ctx.gateway.emitActualizacionReserva).not.toHaveBeenCalled();
    },
  );

  it('valida el estado bajo bloqueo aunque la lectura inicial fuera pendiente', async () => {
    const ctx = preparar('cancelada');
    ctx.repo.findOne.mockResolvedValue({
      ...structuredClone(ctx.almacenada),
      estado: 'pendiente',
    });
    await expect(
      ctx.service.actualizar(9, { estado: 'confirmada' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(ctx.almacenada.estado).toBe('cancelada');
    expect(ctx.manager.save).not.toHaveBeenCalled();
  });

  it.each(ESTADO_RESERVA)(
    'conserva la repetición del mismo estado %s sin emitir un cambio',
    async (estado) => {
      const ctx = preparar(estado);
      await expect(
        ctx.service.actualizar(9, { estado }),
      ).resolves.toMatchObject({ estado });
      expect(ctx.gateway.emitActualizacionReserva).not.toHaveBeenCalled();
      expect(ctx.notificaciones.crearPorCambioDeReserva).not.toHaveBeenCalled();
    },
  );

  it('conserva la actualización sin cambio de estado', async () => {
    const ctx = preparar();
    await expect(
      ctx.service.actualizar(9, { comentarios: 'Comentario actualizado' }),
    ).resolves.toMatchObject({
      estado: 'pendiente',
      comentarios: 'Comentario actualizado',
    });
    expect(ctx.almacenada.comentarios).toBe('Comentario actualizado');
    expect(ctx.gateway.emitActualizacionReserva).not.toHaveBeenCalled();
  });
});

describe('RF-12: PATCH protegido con repositorios ficticios', () => {
  let app: INestApplication;
  let ctx: ReturnType<typeof preparar>;
  let restauranteAsignado: number;
  beforeAll(async () => {
    const source = {
      getRepository: (entity: unknown) => {
        if (entity === UsuarioRol)
          return {
            find: async () => [{ rol: { nombre: 'admin_restaurante' } }],
          };
        if (entity === UsuarioRestaurante)
          return {
            find: async () => [
              { idRestaurante: restauranteAsignado, activo: true },
            ],
          };
        if (entity === 'Reserva')
          return { findOne: async () => ctx.almacenada };
        throw new Error('Repositorio no previsto');
      },
    };
    const acceso = new UsuarioRestauranteAccesoService(source as any);
    const reflector = new Reflector();
    const module = await Test.createTestingModule({
      controllers: [ReservasController],
      providers: [
        {
          provide: ReservasService,
          useValue: {
            actualizar: (id, dto) => ctx.service.actualizar(id, dto),
          },
        },
        { provide: UsuarioRestauranteAccesoService, useValue: acceso },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: (context) => {
          context.switchToHttp().getRequest().user = { id: 42 };
          return true;
        },
      })
      .overrideGuard(RolesGuard)
      .useValue(new RolesGuard(reflector, source as any))
      .overrideGuard(OwnershipGuard)
      .useValue(new OwnershipGuard(reflector, source as any, acceso))
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });
  beforeEach(() => {
    ctx = preparar();
    restauranteAsignado = 3;
  });
  afterAll(async () => {
    if (app) await app.close();
  });

  it.each(['confirmada', 'rechazada'])(
    'el propietario recibe 200 para pendiente -> %s',
    async (estado) => {
      const res = await request(app.getHttpServer())
        .patch('/api/v1/reservas/9')
        .send({ estado })
        .expect(200);
      expect(res.body.estado).toBe(estado);
      expect(ctx.almacenada.estado).toBe(estado);
    },
  );
  it('cancelada -> finalizada responde 400 y no modifica la reserva', async () => {
    ctx = preparar('cancelada');
    await request(app.getHttpServer())
      .patch('/api/v1/reservas/9')
      .send({ estado: 'finalizada' })
      .expect(400);
    expect(ctx.almacenada.estado).toBe('cancelada');
    expect(ctx.manager.save).not.toHaveBeenCalled();
  });
  it('otro administrador recibe 403 sin entrar a la transacción ni guardar', async () => {
    restauranteAsignado = 99;
    await request(app.getHttpServer())
      .patch('/api/v1/reservas/9')
      .send({ estado: 'confirmada' })
      .expect(403);
    expect(ctx.almacenada.estado).toBe('pendiente');
    expect(ctx.transaction).not.toHaveBeenCalled();
    expect(ctx.manager.save).not.toHaveBeenCalled();
  });
});
