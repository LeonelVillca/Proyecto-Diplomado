import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { getMetadataArgsStorage } from 'typeorm';
import request from 'supertest';
import { OwnershipGuard } from '../../core/guards/ownership.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { UsuarioRestauranteAccesoService } from '../usuario-restaurante/usuario-restaurante-acceso.service';
import { Mesa } from './mesa.entity';
import { MesaController } from './mesa.controller';
import { MesaService } from './mesa.service';

describe('RF-11: capacidad de mesas por HTTP con repositorios ficticios', () => {
  let app: INestApplication;
  let almacenada: any;
  let repo: any;
  let service: MesaService;
  let restauranteAsignado: number;
  let transaction: jest.Mock;

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
        if (entity === 'Mesa') return { findOne: async () => almacenada };
        throw new Error('Repositorio no previsto');
      },
    };
    const acceso = new UsuarioRestauranteAccesoService(source as any);
    const reflector = new Reflector();
    const module = await Test.createTestingModule({
      controllers: [MesaController],
      providers: [
        {
          provide: MesaService,
          useValue: {
            crear: (dto) => service.crear(dto),
            actualizar: (id, dto) => service.actualizar(id, dto),
            buscarPorId: (id) => service.buscarPorId(id),
            listarTodos: () => service.listarTodos(),
            listarPorRestaurante: (id) => service.listarPorRestaurante(id),
            eliminar: (id) => service.eliminar(id),
          },
        },
      ],
    })
      // Solo se sustituye la identidad: roles, propiedad, DTO y servicio son reales.
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
    restauranteAsignado = 3;
    almacenada = {
      id: 2,
      numeroMesa: 'A1',
      capacidad: 4,
      estado: 'libre',
      estadoHasta: null,
      restaurante: { id: 3 },
    };
    repo = {
      create: jest.fn((value) => ({ id: 2, ...value })),
      save: jest.fn(async (value) => {
        almacenada = structuredClone(value);
        return value;
      }),
      findOne: jest.fn(async () => structuredClone(almacenada)),
      find: jest.fn(async () =>
        almacenada ? [structuredClone(almacenada)] : [],
      ),
      update: jest.fn().mockResolvedValue({ affected: 0 }),
      delete: jest.fn(async () => {
        almacenada = null;
        return { affected: 1 };
      }),
    };
    const manager = {
      query: jest.fn().mockResolvedValue([]),
      getRepository: () => repo,
    };
    transaction = jest.fn(async (callback) => callback(manager));
    repo.manager = { transaction };
    service = new MesaService(repo, {
      findOneBy: async () => ({ id: 3 }),
    } as any);
  });
  afterAll(async () => {
    if (app) await app.close();
  });

  it.each([1, 4, '6'])(
    'crea una mesa con capacidad válida %j',
    async (capacidad) => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/mesa')
        .send({ idRestaurante: 3, numeroMesa: 'Nueva', capacidad })
        .expect(201);
      expect(res.body.capacidad).toBe(Number(capacidad));
      expect(almacenada.capacidad).toBe(Number(capacidad));
      expect(repo.save).toHaveBeenCalledTimes(1);
    },
  );

  const invalidas: Array<[string, unknown]> = [
    ['ausente', undefined],
    ['null', null],
    ['cero', 0],
    ['negativa', -1],
    ['decimal', 2.5],
    ['texto', 'no-numero'],
    ['cadena vacía', ''],
    ['booleano true', true],
    ['booleano false', false],
    ['arreglo', [4]],
    ['objeto', {}],
  ];
  it.each(invalidas)(
    'rechaza crear con capacidad %s sin guardar',
    async (_caso, capacidad) => {
      const original = structuredClone(almacenada);
      const res = await request(app.getHttpServer())
        .post('/api/v1/mesa')
        .send({ idRestaurante: 3, numeroMesa: 'Nueva', capacidad })
        .expect(400);
      expect(res.body.message).toEqual(
        expect.arrayContaining([expect.stringMatching(/capacidad/)]),
      );
      expect(repo.save).not.toHaveBeenCalled();
      expect(almacenada).toEqual(original);
    },
  );

  it('actualiza otros datos sin enviar capacidad y conserva su valor', async () => {
    const res = await request(app.getHttpServer())
      .patch('/api/v1/mesa/2')
      .send({ numeroMesa: 'A2' })
      .expect(200);
    expect(res.body).toMatchObject({ numeroMesa: 'A2', capacidad: 4 });
    expect(almacenada.capacidad).toBe(4);
    expect(transaction).toHaveBeenCalledTimes(1);
  });
  it('actualiza la capacidad válida', async () => {
    await request(app.getHttpServer())
      .patch('/api/v1/mesa/2')
      .send({ capacidad: 8 })
      .expect(200);
    expect(almacenada.capacidad).toBe(8);
  });
  it.each(invalidas.filter(([caso]) => caso !== 'ausente'))(
    'rechaza actualizar con capacidad %s sin guardar ni alterar la mesa',
    async (_caso, capacidad) => {
      const original = structuredClone(almacenada);
      const res = await request(app.getHttpServer())
        .patch('/api/v1/mesa/2')
        .send({ numeroMesa: 'No debe cambiar', capacidad })
        .expect(400);
      expect(res.body.message).toEqual(
        expect.arrayContaining([expect.stringMatching(/capacidad/)]),
      );
      expect(transaction).not.toHaveBeenCalled();
      expect(repo.save).not.toHaveBeenCalled();
      expect(almacenada).toEqual(original);
    },
  );

  it.each(['crear', 'actualizar', 'eliminar'])(
    'bloquea %s mesas de un restaurante ajeno',
    async (operacion) => {
      restauranteAsignado = 99;
      const original = structuredClone(almacenada);
      const server = request(app.getHttpServer());
      if (operacion === 'crear')
        await server
          .post('/api/v1/mesa')
          .send({ idRestaurante: 3, numeroMesa: 'Nueva', capacidad: 4 })
          .expect(403);
      else if (operacion === 'actualizar')
        await server.patch('/api/v1/mesa/2').send({ capacidad: 8 }).expect(403);
      else await server.delete('/api/v1/mesa/2').expect(403);
      expect(repo.save).not.toHaveBeenCalled();
      expect(repo.delete).not.toHaveBeenCalled();
      expect(almacenada).toEqual(original);
    },
  );

  it('mantiene el ciclo CRUD autorizado con una mesa ficticia', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/mesa')
      .send({ idRestaurante: 3, numeroMesa: 'Nueva', capacidad: 4 })
      .expect(201);
    const lista = await request(app.getHttpServer())
      .get('/api/v1/mesa/restaurante/3')
      .expect(200);
    expect(lista.body).toHaveLength(1);
    const detalle = await request(app.getHttpServer())
      .get('/api/v1/mesa/2')
      .expect(200);
    expect(detalle.body.capacidad).toBe(4);
    await request(app.getHttpServer())
      .patch('/api/v1/mesa/2')
      .send({ capacidad: 6 })
      .expect(200);
    expect(almacenada.capacidad).toBe(6);
    await request(app.getHttpServer()).delete('/api/v1/mesa/2').expect(200);
    expect(almacenada).toBeNull();
    expect(repo.delete).toHaveBeenCalledWith(2);
  });

  it('declara capacidad obligatoria y no nullable en la entidad', () => {
    const columna = getMetadataArgsStorage().columns.find(
      (item) => item.target === Mesa && item.propertyName === 'capacidad',
    );
    expect(columna?.options).toMatchObject({ type: 'int', nullable: false });
  });
});
