import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Reserva } from './reserva.entity';
import { ReservasGateway } from './reservas.gateway';

type ReservaFinalizada = {
  id: number;
  idUsuario: number;
  idRestaurante: number;
};

@Injectable()
export class ReservasFinalizacionService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(ReservasFinalizacionService.name);
  private temporizador?: ReturnType<typeof setInterval>;
  private ejecucion?: Promise<number>;

  constructor(
    @InjectRepository(Reserva)
    private readonly reservasRepo: Repository<Reserva>,
    private readonly reservasGateway: ReservasGateway,
  ) {}

  onModuleInit(): void {
    this.temporizador = setInterval(() => {
      void this.finalizarVencidas().catch((error: unknown) =>
        this.logger.error(
          'No se pudieron finalizar las reservas vencidas',
          error,
        ),
      );
    }, 30_000);
    this.temporizador.unref();
    void this.finalizarVencidas().catch((error: unknown) =>
      this.logger.error(
        'No se pudieron finalizar las reservas vencidas',
        error,
      ),
    );
  }

  onModuleDestroy(): void {
    if (this.temporizador) clearInterval(this.temporizador);
  }

  async finalizarVencidas(): Promise<number> {
    if (this.ejecucion) return this.ejecucion;
    const ejecucion = this.actualizarVencidas();
    this.ejecucion = ejecucion;
    try {
      return await ejecucion;
    } finally {
      if (this.ejecucion === ejecucion) this.ejecucion = undefined;
    }
  }

  private async actualizarVencidas(): Promise<number> {
    // La actualización condicional evita finalizar reservas canceladas o
    // rechazadas y permite ejecutar el proceso en varias instancias.
    // TypeORM devuelve [filas, cantidad] para UPDATE ... RETURNING en PostgreSQL.
    const resultado: unknown = await this.reservasRepo.query(`
      UPDATE reservas AS r
      SET estado = 'finalizada', actualizado_at = NOW()
      FROM mesa AS m, restaurante AS restaurante
      WHERE r.id_mesa = m.id_mesa
        AND m.id_restaurante = restaurante.id_restaurante
        AND r.estado = 'confirmada'
        AND (
          ((r.fecha + r.hora) AT TIME ZONE
            COALESCE(NULLIF(restaurante.zona_horaria, ''), 'America/La_Paz'))
          + (r.duracion_minutos * INTERVAL '1 minute')
        ) <= NOW()
      RETURNING r.id_reserva AS "id",
                r.id_usuario AS "idUsuario",
                m.id_restaurante AS "idRestaurante"
    `);
    if (!Array.isArray(resultado) || !Array.isArray(resultado[0])) {
      throw new Error('Respuesta inesperada al finalizar reservas');
    }
    const finalizadas = resultado[0] as ReservaFinalizada[];

    await Promise.allSettled(
      finalizadas.map((reserva) =>
        this.reservasGateway.emitActualizacionReserva(
          reserva.id,
          'finalizada',
          reserva.idRestaurante,
          reserva.idUsuario,
        ),
      ),
    );
    return finalizadas.length;
  }
}
