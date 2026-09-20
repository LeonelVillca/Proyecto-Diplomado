import { OwnershipGuard } from './ownership.guard';
import { Restaurante } from '../../modules/restaurante/restaurante.entity';
import { UsuarioRol } from '../../modules/usuario-rol/usuario-rol.entity';

describe('Aislamiento de restaurantes', () => {
  function setup(resource: string, params: any, body: any, records: Record<string, any> = {}) {
    const source = { getRepository: jest.fn((entity) => {
      if (entity === UsuarioRol) return { find: async () => [{ rol: { nombre: 'admin_restaurante' } }] };
      if (entity === Restaurante) return { find: async () => [{ id: 10 }] };
      return { findOne: async ({ where }: any) => records[entity + ':' + where.id] };
    }) };
    const guard = new OwnershipGuard({ get: () => resource } as any, source as any);
    const context = { getHandler: () => ({}), switchToHttp: () => ({ getRequest: () => ({ user: { id: 1 }, params, body }) }) } as any;
    return () => guard.canActivate(context);
  }
  it('permite editar la mesa propia sin pedir idRestaurante en el body', async () => {
    await expect(setup('mesa', { id: '8' }, {}, { 'Mesa:8': { restaurante: { id: 10 } } })()).resolves.toBe(true);
  });
  it('rechaza mesa ajena aunque se envíe un restaurante propio', async () => {
    await expect(setup('mesa', { id: '8' }, { idRestaurante: 10 }, { 'Mesa:8': { restaurante: { id: 20 } } })()).rejects.toThrow();
  });
  it('rechaza mover una reserva ajena a una mesa propia', async () => {
    await expect(setup('reserva', { id: '8' }, { idMesa: 5 }, { 'Reserva:8': { mesa: { restaurante: { id: 20 } } }, 'Mesa:5': { restaurante: { id: 10 } } })()).rejects.toThrow();
  });
  it('rechaza mover una reserva propia a una mesa ajena', async () => {
    await expect(setup('reserva', { id: '8' }, { idMesa: 5 }, { 'Reserva:8': { mesa: { restaurante: { id: 10 } } }, 'Mesa:5': { restaurante: { id: 20 } } })()).rejects.toThrow();
  });
  it('resuelve el restaurante del menú al crear un plato', async () => {
    await expect(setup('plato', {}, { idMenu: 3 }, { 'Menu:3': { restaurante: { id: 10 } } })()).resolves.toBe(true);
  });
  it('no confunde el ID de una imagen con el ID de un restaurante', async () => {
    await expect(setup('imagen', { id: 10 }, {}, { 'Imagen:10': { restaurante: { id: 20 } } })()).rejects.toThrow();
  });
  it.each(['../20', '0', '-1', 'NaN'])('rechaza identificador de upload %s', async (id) => {
    await expect(setup('plato', { idRestaurante: id }, {})()).rejects.toThrow();
  });
});
