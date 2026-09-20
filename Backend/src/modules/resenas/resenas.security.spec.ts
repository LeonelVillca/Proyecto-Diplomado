import { BadRequestException } from '@nestjs/common';
import { ResenasService } from './resenas.service';
import { Resena } from './resena.entity';

describe('Límite de creación de reseñas', () => {
  const dto = { idUsuario: 4, idRestaurante: 7, calificacion: 5, comentario: 'Bien' };

  function setup(ledgerResult: unknown[], existing: Resena | null = null) {
    const manager = {
      findOne: jest.fn(async () => existing),
      query: jest.fn(async () => ledgerResult),
      create: jest.fn((_entity, value) => value),
      save: jest.fn(async (value) => value),
    };
    const source = { transaction: jest.fn(async (callback) => callback(manager)) };
    const service = new ResenasService(
      {} as any,
      { findOne: async () => ({ id: dto.idUsuario }) } as any,
      { findOne: async () => ({ id: dto.idRestaurante }) } as any,
      {} as any,
      {} as any,
      source as any,
    );
    return { service, manager, source };
  }

  it('guarda la primera reseña y registra la fecha en la misma transacción', async () => {
    const { service, manager, source } = setup([{ id_usuario: dto.idUsuario }]);
    await expect(service.crear(dto)).resolves.toEqual(expect.objectContaining({ calificacion: 5 }));
    expect(source.transaction).toHaveBeenCalledTimes(1);
    expect(manager.query).toHaveBeenCalledWith(expect.stringContaining('ON CONFLICT'), [4, 7]);
    expect(manager.save).toHaveBeenCalledTimes(1);
  });

  it('impide recrear una reseña durante el plazo tras borrarla', async () => {
    const { service, manager } = setup([]);
    await expect(service.crear(dto)).rejects.toBeInstanceOf(BadRequestException);
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('no toca el control si ya hay una reseña visible', async () => {
    const { service, manager } = setup([{ id_usuario: 4 }], { id: 1 } as Resena);
    await expect(service.crear(dto)).rejects.toBeInstanceOf(BadRequestException);
    expect(manager.query).not.toHaveBeenCalled();
  });
});
