import { BadRequestException } from '@nestjs/common';
import { ReservasService } from './reservas.service';

const horario = { horaInicio: '12:00', horaFin: '16:00' };
const consulta = {
  idRestaurante: 7,
  fecha: '2026-09-25',
  hora: '13:00',
  numeroPersonas: 2,
  duracionMinutos: 120,
};
const mesas = [
  { id: 1, numeroMesa: 'A', capacidad: 2, estado: 'libre' },
  { id: 2, numeroMesa: 'B', capacidad: 4, estado: 'libre' },
];

function crearServicio(idsOcupadas: number[]) {
  const queryBuilder = {
    select: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    addOrderBy: jest.fn().mockReturnThis(),
    getRawMany: jest
      .fn()
      .mockResolvedValue(
        idsOcupadas.map((idMesa) => ({ idMesa: String(idMesa) })),
      ),
    getMany: jest.fn().mockResolvedValue([]),
  };
  const reservasRepo = {
    createQueryBuilder: jest.fn().mockReturnValue(queryBuilder),
    save: jest.fn(),
  };
  const mesasRepo = { find: jest.fn().mockResolvedValue(mesas) };
  const service = new ReservasService(
    reservasRepo as any,
    {} as any,
    mesasRepo as any,
    { find: jest.fn().mockResolvedValue([horario]) } as any,
    { findOne: jest.fn().mockResolvedValue(null) } as any,
    {} as any,
  );
  return { service, reservasRepo, mesasRepo, queryBuilder };
}

describe('Disponibilidad de reservas', () => {
  it('elige otra mesa cuando la primera tiene una reserva activa en el intervalo', async () => {
    const { service, mesasRepo, queryBuilder } = crearServicio([1]);
    await expect(service.consultarDisponibilidad(consulta)).resolves.toEqual({
      mesas: [{ idMesa: 2, numeroMesa: 'B', capacidad: 4 }],
    });
    expect(mesasRepo.find).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          restaurante: { id: 7 },
          estado: 'libre',
        }),
      }),
    );
    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      'reserva.id_mesa IN (:...ids)',
      { ids: [1, 2] },
    );
    expect(queryBuilder.where).toHaveBeenCalledWith(
      "reserva.estado IN ('pendiente', 'confirmada')",
    );
    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      expect.stringContaining('reserva.fecha + reserva.hora <'),
      expect.objectContaining({
        fecha: consulta.fecha,
        hora: consulta.hora,
        duracionMinutos: 120,
      }),
    );
    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      expect.stringContaining('(reserva.duracion_minutos * INTERVAL'),
      expect.objectContaining({ fecha: consulta.fecha, hora: consulta.hora }),
    );
  });

  it('no ofrece ninguna mesa cuando todas las aptas están reservadas', async () => {
    const { service } = crearServicio([1, 2]);
    await expect(service.consultarDisponibilidad(consulta)).resolves.toEqual({
      mesas: [],
    });
  });

  it('devuelve la mesa y la reserva activa que bloquea el horario consultado', async () => {
    const { service, reservasRepo, queryBuilder } = crearServicio([]);
    reservasRepo.createQueryBuilder.mockReturnValue(queryBuilder);
    queryBuilder.getMany.mockResolvedValue([
      {
        id: 81,
        estado: 'pendiente',
        fecha: consulta.fecha,
        hora: '13:30',
        duracionMinutos: 120,
        numeroPersonas: 2,
        mesa: { id: 1 },
        usuario: { nombre: 'Ana', apellido: 'Pérez' },
      },
    ] as any);
    const mesasRepo = (service as any).mesasRepo;
    mesasRepo.find.mockResolvedValue([
      { id: 1, numeroMesa: 'A', capacidad: 2, estado: 'libre' },
      { id: 2, numeroMesa: 'B', capacidad: 4, estado: 'libre' },
    ]);

    await expect(
      service.consultarOcupacionRestaurante(7, consulta.fecha, '14:00'),
    ).resolves.toMatchObject({
      mesas: [
        {
          idMesa: 1,
          disponible: false,
          reserva: { id: 81, cliente: 'Ana Pérez', estado: 'pendiente' },
        },
        { idMesa: 2, disponible: true, reserva: null },
      ],
    });
    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      'reserva.id_mesa IN (:...ids)',
      { ids: [1, 2] },
    );
  });

  it('rechaza el POST aunque el cliente envíe una mesa reservada directamente', async () => {
    const { service, reservasRepo } = crearServicio([]);
    const getCount = jest.fn().mockResolvedValue(1);
    reservasRepo.createQueryBuilder.mockReturnValue({
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getCount,
    });
    (service as any).usuariosRepo.findOne = jest
      .fn()
      .mockResolvedValue({ id: 3 });
    (service as any).mesasRepo.findOne = jest.fn().mockResolvedValue({
      id: 1,
      capacidad: 2,
      estado: 'libre',
      restaurante: { id: 7 },
    });
    await expect(
      service.crear({
        idUsuario: 3,
        idMesa: 1,
        fecha: consulta.fecha,
        hora: consulta.hora,
        numeroPersonas: 2,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(reservasRepo.save).not.toHaveBeenCalled();
  });

  it.each(['ocupada', 'reservada', 'inactiva'])(
    'no permite reservar una mesa con estado %s',
    async (estado) => {
      const { service, reservasRepo } = crearServicio([]);
      (service as any).usuariosRepo.findOne = jest
        .fn()
        .mockResolvedValue({ id: 3 });
      (service as any).mesasRepo.findOne = jest.fn().mockResolvedValue({
        id: 1,
        capacidad: 2,
        estado,
        restaurante: { id: 7 },
      });

      await expect(
        service.crear({
          idUsuario: 3,
          idMesa: 1,
          fecha: consulta.fecha,
          hora: consulta.hora,
          numeroPersonas: 2,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(reservasRepo.save).not.toHaveBeenCalled();
    },
  );
});
