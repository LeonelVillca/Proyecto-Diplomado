import { ReservasGateway } from './reservas.gateway';
import { Restaurante } from '../restaurante/restaurante.entity';

describe('Privacidad de WebSocket de reservas', () => {
  function setup() {
    const makeSocket = (id: number) => ({ data: { auth: { sub: id } }, emit: jest.fn(), disconnect: jest.fn() });
    const sockets = [makeSocket(1), makeSocket(2), makeSocket(3), makeSocket(4), makeSocket(5)];
    const strategy = { validate: jest.fn(async (payload) => {
      if (!payload || payload.sub === 5) throw new Error('revoked');
      return { id: payload.sub };
    }) };
    const source = { getRepository: (entity) => entity === Restaurante
      ? { findOne: async () => ({ solicitud: { estado: 'aprobada', usuario: { id: 2 } } }) }
      : { find: async ({ where }) => where.idUsuario === 2
        ? [{ rol: { nombre: 'admin_restaurante' } }]
        : where.idUsuario === 4 ? [{ rol: { nombre: 'admin_sistema' } }] : [] } };
    const gateway = new ReservasGateway({ verifyAsync: async () => ({ sub: 1 }) } as any, strategy as any, source as any);
    gateway.server = { sockets: { sockets: new Map(sockets.map((s, i) => [String(i), s])) } } as any;
    return { gateway, sockets, strategy };
  }
  it('envía solo al cliente, dueño y administrador autorizado; desconecta al revocado', async () => {
    const { gateway, sockets } = setup();
    const event = { id: 10, idUsuario: 1, idRestaurante: 8, estado: 'pendiente' };
    await gateway.emitNuevaReserva(event);
    for (const index of [0, 1, 3]) expect(sockets[index].emit).toHaveBeenCalledWith('nueva_reserva', event);
    expect(sockets[2].emit).not.toHaveBeenCalled();
    expect(sockets[4].emit).not.toHaveBeenCalled();
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
