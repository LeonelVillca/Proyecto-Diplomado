import { PerfilRestauranteService } from './services/perfil-restaurante.service';
import {
  PublicacionRestauranteService,
  DatosPublicacion,
} from './services/publicacion-restaurante.service';

const perfil = (completo = true): DatosPublicacion =>
  ({
    id: 7,
    estado: false,
    solicitud: { estado: 'aprobada' },
    nombre: 'Restaurante prueba',
    tipoComida: 'Típica',
    tiposComida: [],
    descripcion: 'Comida local',
    telefono: '70000000',
    correo: 'prueba@example.test',
    fotoPortada: 'https://example.test/portada.webp',
    logo: 'https://example.test/logo.webp',
    direccion: completo ? 'Tarija 123' : null,
    latitud: -21.53,
    longitud: -64.73,
    horarios: [{ diaSemana: 0 }],
    mesas: [{ id: 1 }],
  }) as unknown as DatosPublicacion;

describe('Publicación de restaurante', () => {
  const publicacion = new PublicacionRestauranteService();

  it('publica solo perfiles activos y completos', () => {
    expect(publicacion.perfilCompleto(perfil())).toBe(true);
    expect(publicacion.perfilCompleto(perfil(false))).toBe(false);
    expect(publicacion.perfilPublicable(perfil())).toBe(false);
    expect(publicacion.perfilPublicable({ ...perfil(), estado: true })).toBe(
      true,
    );
  });

  it('activa un perfil que pasa de incompleto a completo', async () => {
    const update = jest.fn();
    const manager = { getRepository: () => ({ update }) };
    await publicacion.activarSiPerfilCompleto(
      7,
      false,
      perfil(),
      manager as any,
    );
    expect(update).toHaveBeenCalledWith(
      { id: 7, estado: false },
      { estado: true },
    );
  });

  it('respeta una suspensión administrativa y un perfil incompleto', async () => {
    const update = jest.fn();
    const manager = { getRepository: () => ({ update }) };
    await publicacion.activarSiPerfilCompleto(
      7,
      true,
      perfil(),
      manager as any,
    );
    await publicacion.activarSiPerfilCompleto(
      7,
      false,
      perfil(false),
      manager as any,
    );
    expect(update).not.toHaveBeenCalled();
  });
});

describe('PerfilRestauranteService: coordinación', () => {
  const publicacion = new PublicacionRestauranteService();
  const restaurante = perfil();

  function crearServicio(completo = true) {
    const restauranteRepository = {
      save: jest.fn().mockImplementation(async (value) => value),
    };
    const consultas = {
      datosParaPublicacion: jest.fn().mockResolvedValue(perfil(completo)),
      buscarPorId: jest.fn().mockResolvedValue(restaurante),
    };
    const service = new PerfilRestauranteService(
      restauranteRepository as any,
      {} as any,
      {} as any,
      {} as any,
      consultas as any,
      publicacion,
      {} as any,
    );
    return { service, restauranteRepository, consultas };
  }

  it('rechaza activar administrativamente un perfil incompleto', async () => {
    const { service, restauranteRepository } = crearServicio(false);
    await expect(
      service.cambiarEstadoComoAdministrador(7, true),
    ).rejects.toThrow('Completa la ubicación');
    expect(restauranteRepository.save).not.toHaveBeenCalled();
  });

  it('permite activar administrativamente un perfil completo', async () => {
    const { service, restauranteRepository } = crearServicio();
    await service.cambiarEstadoComoAdministrador(7, true);
    expect(restauranteRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ id: 7, estado: true }),
    );
  });

  it('no reactiva una asignación revocada al consultar mis restaurantes', async () => {
    const manager = {
      query: jest.fn(),
      find: jest.fn().mockResolvedValue([]),
      findOne: jest.fn().mockImplementation(async (entity) => {
        if (entity.name === 'Solicitud')
          return { id: 10, usuario: { correo: 'admin@example.test' } };
        if (entity.name === 'Restaurante') return { id: 7 };
        return { idUsuario: 42, idRestaurante: 7, activo: false };
      }),
      save: jest.fn(),
    };
    const repo = {
      manager: { transaction: jest.fn((callback) => callback(manager)) },
    };
    const asignaciones = { find: jest.fn().mockResolvedValue([]) };
    const consultas = { listarPorIds: jest.fn().mockResolvedValue([]) };
    const service = new PerfilRestauranteService(
      repo as any,
      {} as any,
      asignaciones as any,
      {} as any,
      consultas as any,
      publicacion,
      {} as any,
    );
    expect(await service.listarPorUsuario(42)).toEqual([]);
    expect(repo.manager.transaction).toHaveBeenCalledTimes(1);
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('guarda el perfil y evalúa la publicación dentro de la misma transacción', async () => {
    const orden: string[] = [];
    const ubicacionRepository = {
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation((value) => value),
      save: jest.fn().mockImplementation(async (value) => {
        orden.push('ubicacion');
        return value;
      }),
    };
    const horarioService = {
      reemplazarSemanales: jest.fn(async () => {
        orden.push('borrar horarios', 'horarios');
      }),
    };
    const mesasRepository = {
      count: jest.fn().mockResolvedValue(1),
    };
    const manager = {
      query: jest.fn(),
      findOne: jest.fn().mockResolvedValue({ ...perfil(false) }),
      save: jest.fn().mockImplementation(async (value) => {
        orden.push('restaurante');
        return value;
      }),
      getRepository: jest.fn((entity) => {
        if (entity.name === 'Ubicacion') return ubicacionRepository;
        if (entity.name === 'Mesa') return mesasRepository;
        return {
          update: jest.fn().mockImplementation(async () => {
            orden.push('publicacion');
          }),
        };
      }),
    };
    const repo = {
      manager: {
        transaction: jest.fn(async (callback) => {
          await callback(manager);
          orden.push('commit');
        }),
      },
    };
    const consultas = {
      datosParaPublicacion: jest
        .fn()
        .mockResolvedValueOnce(perfil(false))
        .mockResolvedValueOnce(perfil()),
      buscarPorId: jest.fn().mockResolvedValue(perfil()),
    };
    const service = new PerfilRestauranteService(
      repo as any,
      {} as any,
      {} as any,
      {} as any,
      consultas as any,
      publicacion,
      horarioService as any,
    );
    await service.actualizar(7, {
      direccion: 'Tarija 123',
      horarios: [{ diaSemana: 0, horaInicio: '12:00', horaFin: '20:00' }],
      mesasTotal: 1,
      capacidadTotal: 4,
    } as any);
    expect(consultas.datosParaPublicacion).toHaveBeenNthCalledWith(
      1,
      7,
      manager,
    );
    expect(consultas.datosParaPublicacion).toHaveBeenNthCalledWith(
      2,
      7,
      manager,
    );
    expect(horarioService.reemplazarSemanales).toHaveBeenCalledWith(
      manager,
      7,
      [{ diaSemana: 0, horaInicio: '12:00', horaFin: '20:00' }],
    );
    expect(orden).toEqual([
      'restaurante',
      'ubicacion',
      'borrar horarios',
      'horarios',
      'publicacion',
      'commit',
    ]);
  });
});
