import { UsuarioRestauranteAccesoService } from './usuario-restaurante-acceso.service';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from './usuario-restaurante.entity';

describe('Acceso compartido al restaurante', () => {
  function setup(nombresRoles: string[], asignaciones: Array<{ idRestaurante: number; activo: boolean }>) {
    const source = {
      getRepository: (entity: unknown) => entity === UsuarioRol
        ? { find: jest.fn(async () => nombresRoles.map((nombre) => ({ rol: { nombre } }))) }
        : entity === UsuarioRestaurante
          ? { find: jest.fn(async ({ where }: any) => {
              expect(where).toEqual({ idUsuario: 2, activo: true });
              return asignaciones.filter((asignacion) => asignacion.activo);
            }) }
          : null,
    };
    return new UsuarioRestauranteAccesoService(source as any);
  }

  it('autoriza al administrador asignado y rechaza restaurantes ajenos', async () => {
    const servicio = setup(['admin_restaurante'], [
      { idRestaurante: 8, activo: true },
      { idRestaurante: 9, activo: false },
    ]);
    const acceso = await servicio.obtenerAcceso(2);
    expect(servicio.puedeAdministrar(acceso, 8)).toBe(true);
    expect(servicio.puedeAdministrar(acceso, 9)).toBe(false);
  });

  it('no autoriza una asignación sin rol de administrador de restaurante', async () => {
    const servicio = setup([], [{ idRestaurante: 8, activo: true }]);
    expect(servicio.puedeAdministrar(await servicio.obtenerAcceso(2), 8)).toBe(false);
  });

  it('conserva el acceso del administrador de sistema', async () => {
    const servicio = setup(['admin_sistema'], []);
    expect(servicio.puedeAdministrar(await servicio.obtenerAcceso(2), 8)).toBe(true);
  });
});
