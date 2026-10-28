import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { NotFoundException } from '@nestjs/common';
import { RestauranteConsultasService } from './restaurante-consultas.service';
import { PublicacionRestauranteService } from '../services/publicacion-restaurante.service';

describe('RestauranteConsultasService: contrato del catálogo', () => {
  // El mismo contrato ficticio lo interpreta el servicio real de Flutter.
  const contratoPublico = JSON.parse(
    readFileSync(
      resolve(
        __dirname,
        '../../../../../Frontend/test/fixtures/restaurante_publico.json',
      ),
      'utf8',
    ),
  );
  const solicitudInterna = {
    id: 98,
    estado: 'aprobada',
    nitNegocio: 'NIT-SOLO-INTERNO',
    motivoRechazo: 'MOTIVO-SOLO-INTERNO',
    correoVerificadoAt: '2026-09-01T12:00:00Z',
    usuario: { id: 42, correo: 'privado@example.test' },
    documentosAdjuntos: [{ url: 'documento-privado.pdf' }],
  };
  const publicado = { ...contratoPublico, solicitud: solicitudInterna };
  const incompleto = { ...publicado, id: 22, descripcion: null };

  function crearConsultas() {
    const restaurantes = {
      find: jest.fn().mockResolvedValue([publicado, incompleto]),
      findOne: jest.fn().mockResolvedValue(publicado),
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
        {
          restaurante: { id: 21 },
          diaSemana: 0,
          horaInicio: '12:00',
          horaFin: '23:00',
        },
        {
          restaurante: { id: 22 },
          diaSemana: 0,
          horaInicio: '12:00',
          horaFin: '23:00',
        },
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
        .mockResolvedValue([
          { restaurante: { id: 21 }, url: 'https://example.test/galeria.webp' },
        ]),
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
        horarios: contratoPublico.horarios,
        mesas: [{ id: 1 }],
        imagenes: [{ url: 'https://example.test/galeria.webp' }],
        tiposComida: contratoPublico.tiposComida,
      }),
    );
  });

  function serializar(value: unknown) {
    return JSON.parse(JSON.stringify(value));
  }

  function comprobarSinSolicitud(value: unknown) {
    const json = JSON.stringify(value);
    for (const campo of [
      'solicitud',
      'nitNegocio',
      'motivoRechazo',
      'correoVerificadoAt',
      'documentosAdjuntos',
      'NIT-SOLO-INTERNO',
      'MOTIVO-SOLO-INTERNO',
      'privado@example.test',
      'documento-privado.pdf',
    ])
      expect(json).not.toContain(campo);
  }

  it('publica el contrato Flutter sin solicitud ni datos administrativos', async () => {
    const { service } = crearConsultas();
    const lista = serializar(await service.listarTodos());
    expect(lista).toEqual([contratoPublico]);
    comprobarSinSolicitud(lista);
    expect(publicado.solicitud).toEqual(solicitudInterna);
  });

  it.each(['pendiente', 'rechazada'])(
    'no publica una solicitud %s aunque el resto del perfil esté completo',
    async (estado) => {
      const { service, restaurantes } = crearConsultas();
      restaurantes.find.mockResolvedValue([
        { ...publicado, solicitud: { ...solicitudInterna, estado } },
      ]);
      expect(await service.listarTodos()).toEqual([]);
    },
  );

  it('mantiene ocultos los restaurantes inactivos', async () => {
    const { service, restaurantes } = crearConsultas();
    restaurantes.find.mockResolvedValue([{ ...publicado, estado: false }]);
    expect(await service.listarTodos()).toEqual([]);
  });

  it('conserva la publicación de restaurantes sin solicitud', async () => {
    const { service, restaurantes } = crearConsultas();
    restaurantes.find.mockResolvedValue([{ ...publicado, solicitud: null }]);
    expect(serializar(await service.listarTodos())).toEqual([contratoPublico]);
  });

  it('devuelve el catálogo vacío sin consultar relaciones', async () => {
    const { service, restaurantes, ubicaciones } = crearConsultas();
    restaurantes.find.mockResolvedValue([]);
    expect(await service.listarTodos()).toEqual([]);
    expect(ubicaciones.find).not.toHaveBeenCalled();
  });

  it('el ranking que usa Flutter también omite los datos de solicitud', async () => {
    const { service } = crearConsultas();
    const lista = serializar(await service.obtenerRanking());
    expect(lista).toEqual([contratoPublico]);
    comprobarSinSolicitud(lista);
  });

  function prepararDetalle() {
    const setup = crearConsultas();
    const validacion = jest
      .spyOn(setup.service, 'datosParaPublicacion')
      .mockResolvedValue(publicado as any);
    return { ...setup, validacion };
  }

  it('conserva el contrato del detalle y excluye solo la relación interna', async () => {
    // Antes el detalle devolvía la entidad base, sin enriquecerla como el catálogo.
    const {
      direccion,
      latitud,
      longitud,
      horarios,
      mesas,
      imagenes,
      rating,
      reviewCount,
      ...detallePublico
    } = contratoPublico;
    const entidad = { ...detallePublico, solicitud: solicitudInterna };
    // Usar el repositorio del servicio bajo prueba.
    const setup = prepararDetalle();
    setup.restaurantes.findOne.mockResolvedValue(entidad);
    const detalle = serializar(await setup.service.buscarPorIdPublico(21));
    expect(detalle).toEqual(detallePublico);
    comprobarSinSolicitud(detalle);
    expect(entidad.solicitud).toEqual(solicitudInterna);
  });

  it.each(['pendiente', 'rechazada'])(
    'el detalle mantiene el rechazo de una solicitud %s',
    async (estado) => {
      const { service, validacion } = prepararDetalle();
      validacion.mockResolvedValue({
        ...publicado,
        solicitud: { ...solicitudInterna, estado },
      } as any);
      await expect(service.buscarPorIdPublico(21)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    },
  );

  it.each([{ estado: false }, { descripcion: null }])(
    'no devuelve el detalle de un restaurante no publicable: %j',
    async (cambios) => {
      const { service, validacion } = prepararDetalle();
      validacion.mockResolvedValue({ ...publicado, ...cambios } as any);
      await expect(service.buscarPorIdPublico(21)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    },
  );

  it('mantiene 404 para un detalle inexistente', async () => {
    const { service, restaurantes, validacion } = prepararDetalle();
    restaurantes.findOne.mockResolvedValue(null as any);
    await expect(service.buscarPorIdPublico(999)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(validacion).not.toHaveBeenCalled();
  });

  it('conserva la solicitud en la consulta interna de gestión', async () => {
    const { service } = crearConsultas();
    const perfiles = await service.listarPorIds([21, 22]);
    expect(perfiles[0].solicitud).toEqual(solicitudInterna);
    expect(await service.buscarPorId(21)).toBe(publicado);
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
