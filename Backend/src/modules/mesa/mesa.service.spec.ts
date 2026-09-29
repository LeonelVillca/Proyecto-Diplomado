import { MesaService } from './mesa.service';

describe('MesaService', () => {
  it('saves a manual occupied state with a one-hour expiration', async () => {
    const mesa = { id: 4, estado: 'libre', estadoHasta: null };
    const mesaRepository = {
      findOne: jest.fn().mockResolvedValue(mesa),
      update: jest.fn().mockResolvedValue({ affected: 0 }),
      save: jest.fn().mockImplementation(async (record) => record),
    };
    const manager = {
      query: jest.fn().mockResolvedValue([{ id_mesa: 4 }]),
      getRepository: jest.fn().mockReturnValue(mesaRepository),
    };
    (mesaRepository as any).manager = {
      transaction: jest.fn((callback) => callback(manager)),
    };
    const service = new MesaService(mesaRepository as any, {} as any);

    const updated = await service.actualizar(4, { estado: 'ocupada' });

    expect(updated).toMatchObject({
      id: 4,
      estado: 'ocupada',
      estadoHasta: expect.any(Date),
    });
    expect(updated.estadoHasta!.getTime()).toBeGreaterThan(Date.now());
    expect(updated.estadoHasta!.getTime()).toBeLessThanOrEqual(
      Date.now() + 60 * 60 * 1000,
    );
    expect(mesaRepository.save).toHaveBeenCalledWith(updated);
  });

  it('persists expired manual table states as available', async () => {
    const mesaRepository = {
      update: jest.fn().mockResolvedValue({ affected: 1 }),
      find: jest.fn().mockResolvedValue([]),
    };
    const service = new MesaService(mesaRepository as any, {} as any);

    await service.listarPorRestaurante(9);

    expect(mesaRepository.update).toHaveBeenCalledWith(
      expect.objectContaining({ estadoHasta: expect.any(Object) }),
      { estado: 'libre', estadoHasta: null },
    );
    expect(mesaRepository.find).toHaveBeenCalledWith({
      where: { restaurante: { id: 9 } },
      relations: { restaurante: true },
    });
  });
});
