import { WebSocketGateway, WebSocketServer, OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import { JwtStrategy, JwtPayload } from '../auth/jwt.strategy';
import { originAllowed } from '../../core/config/security.config';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

type ReservationEvent = { id: number; idUsuario: number; idRestaurante: number; estado: string; [key: string]: unknown };

@WebSocketGateway({
  cors: { origin: (origin, cb) => cb(null, originAllowed(origin)) },
  allowRequest: (req, cb) => cb(null, originAllowed(req.headers.origin)),
  maxHttpBufferSize: 16 * 1024,
})
export class ReservasGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ReservasGateway.name);
  constructor(private readonly jwtService: JwtService, private readonly strategy: JwtStrategy, private readonly dataSource: DataSource) {}

  @WebSocketServer() server: Server;

  afterInit(server: Server) {
    // Autenticar ANTES de permitir que el socket entre en el conjunto de clientes conectados.
    server.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth?.token ?? socket.handshake.headers.authorization?.replace(/^Bearer\s+/i, '');
        if (typeof token !== 'string') throw new Error();
        const payload = await this.jwtService.verifyAsync<JwtPayload>(token);
        await this.strategy.validate(payload);
        socket.data.auth = payload;
        next();
      } catch { next(new Error('Sesión inválida o expirada')); }
    });
  }

  handleConnection(socket: Socket) {
    const payload: JwtPayload = socket.data.auth;
    if (!payload) { socket.disconnect(true); return; }
    const expiresAt = Math.min(payload.exp, payload.sessionStartedAt + 7 * 24 * 3600);
    const timer = setTimeout(() => socket.disconnect(true), Math.max(0, expiresAt * 1000 - Date.now()));
    timer.unref();
    socket.data.expiryTimer = timer;
  }

  handleDisconnect(socket: Socket) { clearTimeout(socket.data.expiryTimer); }

  emitNuevaReserva(event: ReservationEvent) { return this.emitToAuthorized('nueva_reserva', event); }
  emitActualizacionReserva(id: number, estado: string, idRestaurante: number, idUsuario: number) {
    return this.emitToAuthorized('reserva_actualizada', { id, estado, idRestaurante, idUsuario });
  }

  private async emitToAuthorized(name: string, event: ReservationEvent) {
    try {
      const restaurant = await this.dataSource.getRepository(Restaurante).findOne({
        where: { id: event.idRestaurante }, relations: { solicitud: { usuario: true } },
      });
      for (const socket of this.server.sockets.sockets.values()) {
        try {
          // Revalidar cuenta, revocación y propiedad incluso en conexiones ya abiertas.
          const user = await this.strategy.validate(socket.data.auth);
          const roles = await this.dataSource.getRepository(UsuarioRol).find({ where: { idUsuario: user.id }, relations: { rol: true } });
          const systemAdmin = roles.some((r) => r.rol.nombre === 'admin_sistema');
          const owner = restaurant?.solicitud?.estado === 'aprobada' && restaurant.solicitud.usuario.id === user.id
            && roles.some((r) => r.rol.nombre === 'admin_restaurante');
          if (user.id === event.idUsuario || systemAdmin || owner) socket.emit(name, event);
        } catch { socket.disconnect(true); }
      }
    } catch { this.logger.error('No se pudo entregar el evento de reserva'); }
  }
}
