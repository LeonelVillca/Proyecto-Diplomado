import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ReservasService } from './reservas.service';

describe('Cancelación de reservas por el cliente', () => {
  const fecha = '2026-09-29';
  const hora = '16:00:00';
  let reserva: any;
  let manager: any;
  let reservasRepo: any;
  let gateway: any;
  let service: ReservasService;

  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-09-29T19:44:59Z'));
    reserva = {
      id: 9,
      usuario: { id: 26 },
      mesa: { restaurante: { id: 3, zonaHoraria: 'America/La_Paz' } },
      fecha,
      hora,
      estado: 'confirmada',
    };
    manager = {
      query: jest.fn(),
      findOne: jest.fn(async () => reserva),
      save: jest.fn(async (_entity, value) => value),
    };
    gateway = { emitActualizacionReserva: jest.fn() };
    reservasRepo = {
      find: jest.fn(async () => [reserva]),
      manager: {
        transaction: (callback: (manager: any) => unknown) => callback(manager),
      },
    };
    service = new ReservasService(
      reservasRepo,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      gateway as any,
      {} as any,
    );
  });

  afterEach(() => jest.useRealTimers());

  it('envía a la app el límite en la zona horaria del restaurante', async () => {
    const resultado = await service.listarPorUsuario(26);
    expect(resultado[0].cancelarHasta).toBe('2026-09-29T19:45:00.000Z');
  });

  it('permite cancelar antes del límite y comunica el cambio', async () => {
    await expect(service.cancelarPorUsuario(9, 26)).resolves.toEqual({
      id: 9,
      estado: 'cancelada',
    });
    expect(manager.save).toHaveBeenCalledTimes(1);
    expect(gateway.emitActualizacionReserva).toHaveBeenCalledWith(
      9,
      'cancelada',
      3,
      26,
    );
  });

  it('rechaza la cancelación exactamente 15 minutos antes', async () => {
    jest.setSystemTime(new Date('2026-09-29T19:45:00Z'));
    await expect(service.cancelarPorUsuario(9, 26)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('no permite cancelar una reserva ajena', async () => {
    await expect(service.cancelarPorUsuario(9, 27)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(manager.save).not.toHaveBeenCalled();
  });
});
