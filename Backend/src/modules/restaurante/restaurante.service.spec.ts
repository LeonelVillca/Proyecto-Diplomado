import { RestauranteService } from './restaurante.service';

describe('RestauranteService: publicación', () => {
  const perfil = () => ({
    id: 7,
    estado: false,
    solicitud: { estado: 'aprobada' },
    nombre: 'Restaurante prueba',
    tipoComida: 'Típica',
    descripcion: 'Comida local',
    telefono: '70000000',
    correo: 'prueba@example.test',
    fotoPortada: 'https://example.test/portada.webp',
    logo: 'https://example.test/logo.webp',
  });

  function crearServicio(completo = true) {
    const restaurante = perfil();
    const restauranteRepository = {
      findOne: jest.fn().mockResolvedValue(restaurante),
      update: jest.fn().mockResolvedValue({ affected: 1 }),
      save: jest.fn().mockImplementation(async (value) => value),
    };
    const ubicacionRepository = {
      findOne: jest.fn().mockResolvedValue({
        direccion: completo ? 'Tarija 123' : null,
        latitud: -21.53,
        longitud: -64.73,
      }),
    };
    const horarioRepository = {
      find: jest.fn().mockResolvedValue([{ diaSemana: 0 }]),
    };
    const mesaRepository = {
      find: jest.fn().mockResolvedValue([{ id: 1 }]),
    };
    const service = new RestauranteService(
      restauranteRepository as any,
      {} as any,
      ubicacionRepository as any,
      horarioRepository as any,
      mesaRepository as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
    return { service, restauranteRepository };
  }

  it('activa un perfil que pasa de incompleto a completo', async () => {
    const { service, restauranteRepository } = crearServicio();

    await (service as any).activarSiPerfilCompleto(7, false);

    expect(restauranteRepository.update).toHaveBeenCalledWith(
      { id: 7, estado: false },
      { estado: true },
    );
  });

  it('conserva la suspensión administrativa de un perfil ya completo', async () => {
    const { service, restauranteRepository } = crearServicio();

    await (service as any).activarSiPerfilCompleto(7, true);

    expect(restauranteRepository.update).not.toHaveBeenCalled();
  });

  it('no activa un perfil al que todavía le falta dirección', async () => {
    const { service, restauranteRepository } = crearServicio(false);

    await (service as any).activarSiPerfilCompleto(7, false);

    expect(restauranteRepository.update).not.toHaveBeenCalled();
  });

  it('rechaza la activación administrativa de un perfil incompleto', async () => {
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
});
