import { RestauranteConsultasService } from './restaurante-consultas.service';
import { PublicacionRestauranteService } from '../services/publicacion-restaurante.service';

describe('RestauranteConsultasService: contrato del catálogo', () => {
  const publicado = {
    id: 21,
    estado: true,
    solicitud: { estado: 'aprobada' },
    nombre: 'Casa Tarija',
    tipoComida: 'Típica',
    tiposComida: [{ id: 1, nombre: 'Típica' }],
    descripcion: 'Comida local',
    telefono: '70000000',
    correo: 'casa@example.test',
    fotoPortada: 'https://example.test/portada.webp',
    logo: 'https://example.test/logo.webp',
  };
  const incompleto = { ...publicado, id: 22, descripcion: null };

  function crearConsultas() {
    const restaurantes = {
      find: jest.fn().mockResolvedValue([publicado, incompleto]),
    };
    const ubicaciones = {
      find: jest.fn().mockResolvedValue([
        {
          restaurante: { id: 21 },
          direccion: 'Tarija 123',
          latitud: -21.53,
          longitud: -64.73,
        },
        {
          restaurante: { id: 22 },
          direccion: 'Tarija 123',
          latitud: -21.53,
          longitud: -64.73,
        },
      ]),
    };
    const horarios = {
      find: jest.fn().mockResolvedValue([
        { restaurante: { id: 21 }, diaSemana: 0 },
        { restaurante: { id: 22 }, diaSemana: 0 },
      ]),
    };
    const mesas = {
      find: jest.fn().mockResolvedValue([
        { restaurante: { id: 21 }, id: 1 },
        { restaurante: { id: 22 }, id: 2 },
      ]),
    };
    const imagenes = {
      find: jest
        .fn()
        .mockResolvedValue([{ restaurante: { id: 21 }, url: 'foto.webp' }]),
    };
    const resenas = {
      find: jest.fn().mockResolvedValue([
        { restaurante: { id: 21 }, calificacion: 4 },
        { restaurante: { id: 21 }, calificacion: 5 },
      ]),
    };
    const service = new RestauranteConsultasService(
      restaurantes as any,
      ubicaciones as any,
      horarios as any,
      mesas as any,
      imagenes as any,
      resenas as any,
      new PublicacionRestauranteService(),
    );
    return {
      service,
      restaurantes,
      ubicaciones,
      horarios,
      mesas,
      imagenes,
      resenas,
    };
  }

  it('conserva los campos que consume Flutter y excluye perfiles incompletos del catálogo', async () => {
    const { service } = crearConsultas();
    const lista = await service.listarTodos();
    expect(lista).toHaveLength(1);
    expect(lista[0]).toEqual(
      expect.objectContaining({
        id: 21,
        direccion: 'Tarija 123',
        latitud: -21.53,
        longitud: -64.73,
        rating: 4.5,
        reviewCount: 2,
        horarios: [{ diaSemana: 0 }],
        mesas: [{ id: 1 }],
        imagenes: [{ url: 'foto.webp' }],
        tiposComida: [{ id: 1, nombre: 'Típica' }],
      }),
    );
  });

  it('consulta cada relacion una vez para todo el catalogo', async () => {
    const { service, ubicaciones, horarios, mesas, imagenes, resenas } =
      crearConsultas();
    await service.listarTodos();
    for (const repo of [ubicaciones, horarios, mesas, imagenes, resenas]) {
      expect(repo.find).toHaveBeenCalledTimes(1);
    }
  });

  it('incluye el perfil incompleto en la consulta de gestión', async () => {
    const { service } = crearConsultas();
    const lista = await service.listarPorIds([21, 22]);
    expect(lista.map((r) => r.id)).toEqual([21, 22]);
  });
});
