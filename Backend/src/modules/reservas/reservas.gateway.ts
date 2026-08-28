import { WebSocketGateway, WebSocketServer, OnGatewayInit } from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ReservasGateway implements OnGatewayInit {
  @WebSocketServer()
  server: Server;

  afterInit(server: Server) {
    console.log('Reservas WebSocket Gateway Inicializado');
  }

  emitNuevaReserva(reserva: any) {
    this.server.emit('nueva_reserva', reserva);
  }

  emitActualizacionReserva(idReserva: number, estado: string, idRestaurante: number) {
    this.server.emit('reserva_actualizada', { id: idReserva, estado, idRestaurante });
  }
}
