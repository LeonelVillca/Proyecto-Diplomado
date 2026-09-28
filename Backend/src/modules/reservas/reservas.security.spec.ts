import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { ReservasController } from './reservas.controller';
import { ReservasService } from './reservas.service';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';

describe('Reservas: concurrencia y acceso', () => {
  it('convierte el conflicto del índice único en respuesta controlada y no emite eventos', async () => {
    const gateway = { emitNuevaReserva: jest.fn() };
    const reservas = {
      findOne: jest.fn(async () => null),
      create: (value: unknown) => value,
      save: jest.fn(async () => {
        throw {
          driverError: {
            code: '23505',
            constraint: 'uq_reserva_mesa_horario_activa',
          },
        };
      }),
    };
    const service = new ReservasService(
      reservas as any,
      { findOne: async () => ({ id: 1 }) } as any,
      { findOne: async () => ({ id: 2, restaurante: { id: 3 } }) } as any,
      {} as any,
      {} as any,
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
