import { WebSocketGateway, WebSocketServer, OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { JwtStrategy, JwtPayload } from '../auth/security/jwt.strategy';
import { originAllowed } from '../../core/config/security.config';
import { UsuarioRestauranteAccesoService } from '../usuario-restaurante/usuario-restaurante-acceso.service';

type ReservationEvent = { id: number; idUsuario: number; idRestaurante: number; estado: string; [key: string]: unknown };

@WebSocketGateway({
  cors: { origin: (origin, cb) => cb(null, originAllowed(origin)) },
  allowRequest: (req, cb) => cb(null, originAllowed(req.headers.origin)),
  maxHttpBufferSize: 16 * 1024,
})
export class ReservasGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ReservasGateway.name);
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly jwtService: JwtService, private readonly strategy: JwtStrategy, private readonly accesoRestaurante: UsuarioRestauranteAccesoService) {}

  @WebSocketServer() server: Server;

  // Inicializa el canal de eventos de reservas.
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

  // Autoriza una conexión al canal de reservas.
  handleConnection(socket: Socket) {
    const payload: JwtPayload = socket.data.auth;
    if (!payload) { socket.disconnect(true); return; }
    const expiresAt = Math.min(payload.exp, payload.sessionStartedAt + 7 * 24 * 3600);
    const timer = setTimeout(() => socket.disconnect(true), Math.max(0, expiresAt * 1000 - Date.now()));
    timer.unref();
    socket.data.expiryTimer = timer;
  }

  // Atiende la desconexión del canal de reservas.
  handleDisconnect(socket: Socket) { clearTimeout(socket.data.expiryTimer); }

  // Publica el evento de una nueva reserva.
  emitNuevaReserva(event: ReservationEvent) { return this.emitToAuthorized('nueva_reserva', event); }
  // Publica el evento de una reserva actualizada.
  emitActualizacionReserva(id: number, estado: string, idRestaurante: number, idUsuario: number) {
    return this.emitToAuthorized('reserva_actualizada', { id, estado, idRestaurante, idUsuario });
  }

  // Envía el evento a los usuarios autorizados.
  private async emitToAuthorized(name: string, event: ReservationEvent) {
    try {
      for (const socket of this.server.sockets.sockets.values()) {
        try {
          // Revalidar cuenta, revocación y propiedad incluso en conexiones ya abiertas.
          const user = await this.strategy.validate(socket.data.auth);
          if (user.id === event.idUsuario) {
            socket.emit(name, event);
            continue;
          }
          const acceso = await this.accesoRestaurante.obtenerAcceso(user.id);
          if (this.accesoRestaurante.puedeAdministrar(acceso, event.idRestaurante))
            socket.emit(name, event);
        } catch { socket.disconnect(true); }
      }
    } catch { this.logger.error('No se pudo entregar el evento de reserva'); }
  }
}
