import { ReservasGateway } from './reservas.gateway';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { UsuarioRestauranteAccesoService } from '../usuario-restaurante/usuario-restaurante-acceso.service';

describe('Privacidad de WebSocket de reservas', () => {
  function setup() {
    const makeSocket = (id: number) => ({ data: { auth: { sub: id } }, emit: jest.fn(), disconnect: jest.fn() });
    const sockets = [makeSocket(1), makeSocket(2), makeSocket(3), makeSocket(4), makeSocket(5), makeSocket(6)];
    const strategy = { validate: jest.fn(async (payload) => {
      if (!payload || payload.sub === 5) throw new Error('revoked');
      return { id: payload.sub };
    }) };
    const asignados = new Set([2]);
    const source = { getRepository: (entity: unknown) => entity === UsuarioRol
      ? { find: async ({ where }: any) => where.idUsuario === 2 || where.idUsuario === 6
        ? [{ rol: { nombre: 'admin_restaurante' } }]
        : where.idUsuario === 4 ? [{ rol: { nombre: 'admin_sistema' } }] : [] }
      : entity === UsuarioRestaurante
        ? { find: async ({ where }: any) => asignados.has(where.idUsuario)
          ? [{ idRestaurante: 8, activo: true }] : [] }
        : null };
    const gateway = new ReservasGateway(
      { verifyAsync: async () => ({ sub: 1 }) } as any,
      strategy as any,
      new UsuarioRestauranteAccesoService(source as any),
    );
    gateway.server = { sockets: { sockets: new Map(sockets.map((s, i) => [String(i), s])) } } as any;
    return { gateway, sockets, strategy, asignados };
  }
  it('envía al cliente, administrador asignado y admin de sistema; excluye al antiguo dueño y desconecta al revocado', async () => {
    const { gateway, sockets } = setup();
    const event = { id: 10, idUsuario: 1, idRestaurante: 8, estado: 'pendiente' };
    await gateway.emitNuevaReserva(event);
    for (const index of [0, 1, 3]) expect(sockets[index].emit).toHaveBeenCalledWith('nueva_reserva', event);
    expect(sockets[2].emit).not.toHaveBeenCalled();
    expect(sockets[4].emit).not.toHaveBeenCalled();
    expect(sockets[5].emit).not.toHaveBeenCalled();
    expect(sockets[4].disconnect).toHaveBeenCalledWith(true);
  });
  it('rechaza el handshake sin credencial antes de conectarlo', async () => {
    const { gateway } = setup();
    let middleware: any;
    gateway.afterInit({ use: (fn) => { middleware = fn; } } as any);
    const next = jest.fn();
    await middleware({ handshake: { auth: {}, headers: {} }, data: {} }, next);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });
  it('deja de enviar eventos al administrador cuya asignación fue revocada', async () => {
    const { gateway, sockets, asignados } = setup();
    const event = { id: 11, idUsuario: 1, idRestaurante: 8, estado: 'confirmada' };
    await gateway.emitNuevaReserva(event);
    expect(sockets[1].emit).toHaveBeenCalledTimes(1);
    asignados.delete(2);
    await gateway.emitNuevaReserva(event);
    expect(sockets[1].emit).toHaveBeenCalledTimes(1);
  });
  it('desconecta una conexión al expirar su JWT', () => {
    jest.useFakeTimers();
    const { gateway } = setup();
    const now = Math.floor(Date.now() / 1000);
    const socket = { data: { auth: { exp: now + 1, sessionStartedAt: now } }, disconnect: jest.fn() };
    gateway.handleConnection(socket as any);
    jest.advanceTimersByTime(1001);
    expect(socket.disconnect).toHaveBeenCalledWith(true);
    gateway.handleDisconnect(socket as any);
    jest.useRealTimers();
  });
});
