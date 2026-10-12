import { BadRequestException, NotFoundException } from '@nestjs/common';
import { In, IsNull, LessThanOrEqual, Or, Repository } from 'typeorm';
import { Mesa } from './mesa.entity';
import { ActualizarEstadoHorarioDto } from './dto/actualizar-estado-horario.dto';

export const DURACION_ESTADO_MESA_MINUTOS = 60;
export const MARGEN_PREVIO_RESERVA_MINUTOS = 30;

// Libera los estados temporales de mesa que ya vencieron.
export async function liberarEstadosMesaVencidos(
  repository: Repository<Mesa>,
  id?: number,
): Promise<void> {
  await repository.update(
    {
      ...(id === undefined ? {} : { id }),
      estado: In(['ocupada', 'reservada']),
      estadoHasta: Or(IsNull(), LessThanOrEqual(new Date())),
    },
    { estado: 'libre', estadoHasta: null },
  );
}

// Convierte una fecha y hora local a un instante real.
export function instanteEnZonaHoraria(
  fecha: string,
  hora: string,
  zonaHoraria: string,
): Date {
  const [year, month, day] = fecha.split('-').map(Number);
  const [hours, minutes, seconds = 0] = hora.split(':').map(Number);
  const wallClockAsUtc = Date.UTC(
    year,
    month - 1,
    day,
    hours,
    minutes,
    seconds,
  );
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: zonaHoraria,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });
  let instant = wallClockAsUtc;
  for (let iteration = 0; iteration < 3; iteration += 1) {
    const parts = Object.fromEntries(
      formatter
        .formatToParts(new Date(instant))
        .filter((part) => part.type !== 'literal')
        .map((part) => [part.type, Number(part.value)]),
    ) as Record<string, number>;
    const renderedAsUtc = Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
      parts.second,
    );
    instant += wallClockAsUtc - renderedAsUtc;
  }
  return new Date(instant);
}

// Obtiene el estado de una mesa en un horario.
export function estadoMesaEnHorario(
  mesa: Mesa,
  fecha: string,
  hora: string,
  duracionMinutos: number,
): Mesa['estado'] {
  if (mesa.estado === 'inactiva' || mesa.estado === 'libre') return mesa.estado;
  if (!mesa.estadoHasta) return 'libre';
  const inicio = instanteEnZonaHoraria(
    fecha,
    hora,
    mesa.restaurante?.zonaHoraria || 'America/La_Paz',
  ).getTime();
  const finEstado = new Date(mesa.estadoHasta).getTime();
  const inicioEstado = finEstado - DURACION_ESTADO_MESA_MINUTOS * 60000;
  const seCruzan =
    duracionMinutos === 0
      ? inicio >= inicioEstado && inicio < finEstado
      : inicio < finEstado && inicio + duracionMinutos * 60000 > inicioEstado;
  return seCruzan ? mesa.estado : 'libre';
}

type BloqueoHorario = {
  id_mesa: number;
  estado: 'ocupada' | 'reservada';
  hora: string;
};

// Busca bloqueos manuales de mesas en un horario.
export async function bloqueosManualesEnHorario(
  idsMesa: number[],
  fecha: string,
  hora: string,
  duracionMinutos: number,
  query: (sql: string, parameters: unknown[]) => Promise<BloqueoHorario[]>,
): Promise<BloqueoHorario[]> {
  if (!idsMesa.length) return [];
  const inicio = 'CAST($2 AS date) + CAST($3 AS time)';
  return query(
    `SELECT id_mesa, estado, to_char(hora, 'HH24:MI') AS hora
     FROM mesa_bloqueo_horario
     WHERE id_mesa = ANY($1::int[])
       AND fecha + hora ${duracionMinutos === 0 ? '<=' : '<'}
         ${inicio} + ($4 * INTERVAL '1 minute')
       AND fecha + hora + INTERVAL '${DURACION_ESTADO_MESA_MINUTOS} minutes' > ${inicio}`,
    [idsMesa, fecha, hora, duracionMinutos],
  );
}

// Actualiza el bloqueo manual de una mesa.
export async function actualizarBloqueoHorario(
  id: number,
  dto: ActualizarEstadoHorarioDto,
  query: (
    sql: string,
    parameters: unknown[],
  ) => Promise<Array<{ id_mesa: number; estado: string }>>,
) {
  const rows = await query(
    'SELECT id_mesa, estado FROM mesa WHERE id_mesa = $1 FOR UPDATE',
    [id],
  );
  if (!rows.length) throw new NotFoundException('Mesa no encontrada');
  if (rows[0].estado === 'inactiva') {
    throw new BadRequestException('La mesa está fuera de servicio');
  }
  if (dto.estado === 'libre') {
    await query(
      'DELETE FROM mesa_bloqueo_horario WHERE id_mesa = $1 AND fecha = $2 AND hora = $3',
      [id, dto.fecha, dto.hora],
    );
  } else {
    const inicio = 'CAST($2 AS date) + CAST($3 AS time)';
    const reservas = await query(
      `SELECT 1 FROM reservas WHERE id_mesa = $1
       AND estado IN ('pendiente', 'confirmada')
       AND fecha + hora - INTERVAL '${MARGEN_PREVIO_RESERVA_MINUTOS} minutes' < ${inicio} + INTERVAL '${DURACION_ESTADO_MESA_MINUTOS} minutes'
       AND fecha + hora + (duracion_minutos * INTERVAL '1 minute') > ${inicio}
       LIMIT 1`,
      [id, dto.fecha, dto.hora],
    );
    if (reservas.length)
      throw new BadRequestException('Ya existe una reserva en ese horario');
    const otrosBloqueos = await query(
      `SELECT 1 FROM mesa_bloqueo_horario WHERE id_mesa = $1
       AND fecha + hora < ${inicio} + INTERVAL '${DURACION_ESTADO_MESA_MINUTOS} minutes'
       AND fecha + hora + INTERVAL '${DURACION_ESTADO_MESA_MINUTOS} minutes' > ${inicio}
       AND NOT (fecha = $2 AND hora = $3) LIMIT 1`,
      [id, dto.fecha, dto.hora],
    );
    if (otrosBloqueos.length) {
      throw new BadRequestException(
        'Ese horario se cruza con otro bloqueo manual de la mesa',
      );
    }
    await query(
      `INSERT INTO mesa_bloqueo_horario (id_mesa, fecha, hora, estado)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id_mesa, fecha, hora) DO UPDATE SET estado = EXCLUDED.estado`,
      [id, dto.fecha, dto.hora, dto.estado],
    );
  }
  return { idMesa: id, ...dto };
}
