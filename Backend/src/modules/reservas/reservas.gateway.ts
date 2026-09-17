import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ReservasGateway implements OnGatewayInit, OnGatewayConnection {
  constructor(private readonly jwtService: JwtService) {}

  @WebSocketServer()
  server: Server;

  afterInit(server: Server) {
    console.log('Reservas WebSocket Gateway Inicializado');
  }

  async handleConnection(socket: Socket) {
    const authToken = socket.handshake.auth?.token as string | undefined;
    const header = socket.handshake.headers.authorization;
    const token = authToken ?? (typeof header === 'string' ? header.replace(/^Bearer\s+/i, '') : undefined);

    if (!token) {
      socket.disconnect(true);
      return;
    }

    try {
      await this.jwtService.verifyAsync(token);
    } catch (_) {
      socket.disconnect(true);
    }
  }

  emitNuevaReserva(reserva: any) {
    this.server.emit('nueva_reserva', reserva);
  }

  emitActualizacionReserva(idReserva: number, estado: string, idRestaurante: number) {
    this.server.emit('reserva_actualizada', { id: idReserva, estado, idRestaurante });
  }
}
