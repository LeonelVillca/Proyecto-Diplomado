import { MesaService } from './mesa.service';

describe('MesaService', () => {
  it('persists a changed table state through the repository', async () => {
    const mesa = { id: 4, estado: 'libre' };
    const mesaRepository = {
      findOne: jest.fn().mockResolvedValue(mesa),
      save: jest.fn().mockImplementation(async (record) => record),
    };
    const service = new MesaService(mesaRepository as any, {} as any);

    await expect(service.actualizar(4, { estado: 'ocupada' })).resolves.toEqual(
      {
        id: 4,
        estado: 'ocupada',
      },
    );
    expect(mesaRepository.save).toHaveBeenCalledWith({
      id: 4,
      estado: 'ocupada',
    });
  });
});
