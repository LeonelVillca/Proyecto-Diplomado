import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { ReservasController } from './reservas.controller';
import { ReservasService } from './reservas.service';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { Mesa } from '../mesa/mesa.entity';
import { Reserva } from './reserva.entity';
import { Usuario } from '../usuarios/usuario.entity';

describe('Reservas: concurrencia y acceso', () => {
  it('convierte el conflicto del índice único en respuesta controlada y no emite eventos', async () => {
    const gateway = { emitNuevaReserva: jest.fn() };
    const reservas = {
      create: (value: unknown) => value,
      createQueryBuilder: () => ({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(0),
      }),
      save: jest.fn(async () => {
        throw {
          driverError: {
            code: '23505',
            constraint: 'uq_reserva_mesa_horario_activa',
          },
        };
      }),
    };
    const mesa = {
      findOne: async () => ({
        id: 2, estado: 'libre', capacidad: 2,
        restaurante: { id: 3 },
      }),
      update: async () => ({ affected: 0 }),
    };
    const usuario = { findOne: async () => ({ id: 1 }) };
    const manager = {
      query: async (sql: string) => sql.includes('mesa_bloqueo_horario')
        ? [] : [{ id_mesa: 2 }],
      getRepository: (entity: unknown) => entity === Mesa
        ? mesa : entity === Usuario ? usuario : entity === Reserva ? reservas : null,
    };
    (reservas as any).manager = {
      transaction: async (callback: (manager: unknown) => Promise<unknown>) => callback(manager),
    };
    const service = new ReservasService(
      reservas as any,
      usuario as any,
      mesa as any,
      { find: async () => [{ horaInicio: '17:00', horaFin: '20:00' }] } as any,
      { findOne: async () => null } as any,
      gateway as any,
      {} as any,
    );
    await expect(
      service.crear({
        idUsuario: 1,
        idMesa: 2,
        fecha: '2026-09-20',
        hora: '18:00',
        numeroPersonas: 2,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(gateway.emitNuevaReserva).not.toHaveBeenCalled();
  });

  it('autoriza al dueño del restaurante consultando roles actuales de la BD', async () => {
    const reserva = { usuario: { id: 1 }, mesa: { restaurante: { id: 8 } } };
    const source = {
      getRepository: (entity: unknown) =>
        entity === UsuarioRol
          ? { find: async () => [{ rol: { nombre: 'admin_restaurante' } }] }
          : entity === UsuarioRestaurante
            ? { findOne: async () => ({ idRestaurante: 8 }) }
            : null,
    };
    const controller = new ReservasController(
      { buscarPorId: async () => reserva } as any,
      source as any,
    );
    await expect(controller.buscarPorId(5, { user: { id: 2 } })).resolves.toBe(
      reserva,
    );
  });

  it('rechaza a otro administrador de restaurante aunque tenga ese rol', async () => {
    const reserva = { usuario: { id: 1 }, mesa: { restaurante: { id: 8 } } };
    const source = {
      getRepository: (entity: unknown) =>
        entity === UsuarioRol
          ? { find: async () => [{ rol: { nombre: 'admin_restaurante' } }] }
          : entity === UsuarioRestaurante
            ? { findOne: async () => null }
            : null,
    };
    const controller = new ReservasController(
      { buscarPorId: async () => reserva } as any,
      source as any,
    );
    await expect(
      controller.buscarPorId(5, { user: { id: 3 } }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
