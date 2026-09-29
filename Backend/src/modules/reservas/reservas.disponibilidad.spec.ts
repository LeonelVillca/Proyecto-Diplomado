import { BadRequestException } from '@nestjs/common';
import { Mesa } from '../mesa/mesa.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Reserva } from './reserva.entity';
import { ReservasService } from './reservas.service';

const horario = { horaInicio: '12:00', horaFin: '16:00' };
const consulta = {
  idRestaurante: 7,
  fecha: '2026-09-25',
  hora: '13:00',
  numeroPersonas: 2,
  duracionMinutos: 60,
};
const mesas = [
  { id: 1, numeroMesa: 'A', capacidad: 2, estado: 'libre' },
  { id: 2, numeroMesa: 'B', capacidad: 4, estado: 'libre' },
];

type Bloqueo = {
  id_mesa: number;
  fecha: string;
  hora: string;
  estado: 'ocupada' | 'reservada';
};

function crearServicio(idsOcupadas: number[], bloqueos: Bloqueo[] = []) {
  const bloqueosEnHorario = (parameters: unknown[]) => {
    const [ids, fecha, hora, duracion] = parameters as [number[], string, string, number];
    const inicio = Date.parse(`${fecha}T${hora}:00Z`);
    const fin = inicio + duracion * 60000;
    return bloqueos.filter((bloqueo) => {
      const desde = Date.parse(`${bloqueo.fecha}T${bloqueo.hora}:00Z`);
      return ids.includes(bloqueo.id_mesa) &&
        (duracion === 0 ? desde <= inicio : desde < fin) &&
        desde + 3600000 > inicio;
    });
  };
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
    getCount: jest.fn().mockResolvedValue(0),
  };
  const reservasRepo = {
    createQueryBuilder: jest.fn().mockReturnValue(queryBuilder),
    create: jest.fn((reserva) => reserva),
    save: jest.fn(),
  };
  const mesasRepo = {
    find: jest.fn().mockResolvedValue(mesas),
    findOne: jest.fn(),
    update: jest.fn().mockResolvedValue({ affected: 0 }),
    query: jest.fn((sql, parameters) => Promise.resolve(bloqueosEnHorario(parameters))),
  };
  const usuariosRepo = { findOne: jest.fn() };
  const manager = {
    query: jest.fn((sql, parameters) => Promise.resolve(
      sql.includes('mesa_bloqueo_horario')
        ? bloqueosEnHorario(parameters)
        : [{ id_mesa: 1 }],
    )),
    getRepository: jest.fn((entity) => {
      if (entity === Mesa) return mesasRepo;
      if (entity === Reserva) return reservasRepo;
      if (entity === Usuario) return usuariosRepo;
      throw new Error('Repositorio no preparado en esta prueba');
    }),
  };
  (reservasRepo as any).manager = {
    transaction: jest.fn((callback) => callback(manager)),
  };
  const service = new ReservasService(
    reservasRepo as any,
    usuariosRepo as any,
    mesasRepo as any,
    { find: jest.fn().mockResolvedValue([horario]) } as any,
    { findOne: jest.fn().mockResolvedValue(null) } as any,
    { emitNuevaReserva: jest.fn() } as any,
  );
  return {
    service,
    reservasRepo,
    mesasRepo,
    usuariosRepo,
    queryBuilder,
    manager,
  };
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
          estado: expect.any(Object),
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
      expect.stringContaining(
        "reserva.fecha + reserva.hora - (30 * INTERVAL '1 minute') <",
      ),
      expect.objectContaining({
        fecha: consulta.fecha,
        hora: consulta.hora,
        duracionMinutos: 60,
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

  it('no deja que una marca manual de ahora bloquee las reservas de mañana', async () => {
    const { service, mesasRepo } = crearServicio([]);
    mesasRepo.find.mockResolvedValue([
      {
        id: 1,
        numeroMesa: 'A',
        capacidad: 2,
        estado: 'reservada',
        estadoHasta: new Date(Date.now() + 30 * 60 * 1000),
        restaurante: { id: 7, zonaHoraria: 'America/La_Paz' },
      },
    ] as any);

    await expect(
      service.consultarDisponibilidad({
        ...consulta,
        fecha: '2026-09-30',
        hora: '13:00',
      }),
    ).resolves.toEqual({
      mesas: [{ idMesa: 1, numeroMesa: 'A', capacidad: 2 }],
    });
  });

  it('bloquea solo el horario que cruza la hora manual de ocupación', async () => {
    const { service, mesasRepo } = crearServicio([]);
    mesasRepo.find.mockResolvedValue([
      {
        id: 1,
        numeroMesa: 'A',
        capacidad: 2,
        estado: 'ocupada',
        estadoHasta: new Date('2026-09-25T18:00:00.000Z'),
        restaurante: { id: 7, zonaHoraria: 'America/La_Paz' },
      },
    ] as any);

    await expect(
      service.consultarDisponibilidad({ ...consulta, hora: '13:00' }),
    ).resolves.toEqual({ mesas: [] });
    await expect(
      service.consultarDisponibilidad({ ...consulta, hora: '14:00' }),
    ).resolves.toEqual({
      mesas: [{ idMesa: 1, numeroMesa: 'A', capacidad: 2 }],
    });
  });

  it('un bloqueo del horario elegido deja libre la misma mesa a otra hora y al día siguiente', async () => {
    const { service } = crearServicio([], [{
      id_mesa: 1, fecha: consulta.fecha, hora: '13:00', estado: 'reservada',
    }]);

    await expect(service.consultarDisponibilidad(consulta)).resolves.toEqual({
      mesas: [{ idMesa: 2, numeroMesa: 'B', capacidad: 4 }],
    });
    await expect(service.consultarDisponibilidad({ ...consulta, hora: '14:00' }))
      .resolves.toEqual({ mesas: [
        { idMesa: 1, numeroMesa: 'A', capacidad: 2 },
        { idMesa: 2, numeroMesa: 'B', capacidad: 4 },
      ] });
    await expect(service.consultarDisponibilidad({ ...consulta, fecha: '2026-09-26' }))
      .resolves.toEqual({ mesas: [
        { idMesa: 1, numeroMesa: 'A', capacidad: 2 },
        { idMesa: 2, numeroMesa: 'B', capacidad: 4 },
      ] });
  });

  it('muestra el bloqueo manual únicamente en la consulta de ese horario', async () => {
    const { service } = crearServicio([], [{
      id_mesa: 1, fecha: consulta.fecha, hora: '13:00', estado: 'ocupada',
    }]);

    const aLasTrece = await service.consultarOcupacionRestaurante(7, consulta.fecha, '13:00');
    expect(aLasTrece.mesas[0]).toMatchObject({
      idMesa: 1, estado: 'ocupada', disponible: false, bloqueoHora: '13:00',
    });
    const aLasCatorce = await service.consultarOcupacionRestaurante(7, consulta.fecha, '14:00');
    expect(aLasCatorce.mesas[0]).toMatchObject({
      idMesa: 1, estado: 'libre', disponible: true, bloqueoHora: null,
    });
  });

  it('rechaza el POST directo que coincide con un bloqueo manual', async () => {
    const { service, usuariosRepo, mesasRepo, reservasRepo } = crearServicio([], [{
      id_mesa: 1, fecha: consulta.fecha, hora: '13:00', estado: 'ocupada',
    }]);
    usuariosRepo.findOne.mockResolvedValue({ id: 3 } as any);
    mesasRepo.findOne.mockResolvedValue({
      id: 1, capacidad: 2, estado: 'libre',
      restaurante: { id: 7, zonaHoraria: 'America/La_Paz' },
    } as any);
    await expect(service.crear({
      idUsuario: 3, idMesa: 1, fecha: consulta.fecha,
      hora: consulta.hora, numeroPersonas: 2,
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(reservasRepo.save).not.toHaveBeenCalled();
  });

  it('permite reservar mañana una mesa marcada manualmente como ocupada ahora', async () => {
    const { service, reservasRepo, mesasRepo, usuariosRepo } = crearServicio(
      [],
    );
    const mesa = {
      id: 1,
      capacidad: 2,
      estado: 'ocupada',
      estadoHasta: new Date(Date.now() + 30 * 60 * 1000),
      restaurante: { id: 7, zonaHoraria: 'America/La_Paz' },
    };
    mesasRepo.findOne.mockResolvedValue(mesa as any);
    usuariosRepo.findOne.mockResolvedValue({ id: 3 } as any);
    reservasRepo.save.mockImplementation(async (reserva) => ({
      ...reserva,
      id: 90,
    }));

    await expect(
      service.crear({
        idUsuario: 3,
        idMesa: 1,
        fecha: '2026-09-30',
        hora: '13:00',
        numeroPersonas: 2,
      }),
    ).resolves.toMatchObject({ estado: 'pendiente', duracionMinutos: 60 });
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
        duracionMinutos: 60,
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
    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      expect.stringContaining("INTERVAL '1 minute') <="),
      expect.objectContaining({ fecha: consulta.fecha, hora: '14:00' }),
    );
  });

  it('rechaza el POST aunque el cliente envíe una mesa reservada directamente', async () => {
    const { service, reservasRepo, usuariosRepo, mesasRepo, manager } =
      crearServicio([]);
    const getCount = jest.fn().mockResolvedValue(1);
    reservasRepo.createQueryBuilder.mockReturnValue({
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getCount,
    });
    usuariosRepo.findOne.mockResolvedValue({ id: 3 } as any);
    mesasRepo.findOne.mockResolvedValue({
      id: 1,
      capacidad: 2,
      estado: 'libre',
      restaurante: { id: 7 },
    } as any);
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
    expect(manager.query).toHaveBeenCalledWith(
      'SELECT id_mesa FROM mesa WHERE id_mesa = $1 FOR UPDATE',
      [1],
    );
  });

  it.each(['ocupada', 'reservada', 'inactiva'])(
    'no permite reservar una mesa con estado %s',
    async (estado) => {
      const { service, reservasRepo, usuariosRepo, mesasRepo } = crearServicio(
        [],
      );
      usuariosRepo.findOne.mockResolvedValue({ id: 3 } as any);
      mesasRepo.findOne.mockResolvedValue({
        id: 1,
        capacidad: 2,
        estado,
        estadoHasta: new Date('2026-09-25T18:00:00.000Z'),
        restaurante: { id: 7, zonaHoraria: 'America/La_Paz' },
      } as any);

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
