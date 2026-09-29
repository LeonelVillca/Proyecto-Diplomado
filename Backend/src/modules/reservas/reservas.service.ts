import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  In,
  IsNull,
  LessThanOrEqual,
  MoreThanOrEqual,
  Or,
  Repository,
  SelectQueryBuilder,
} from 'typeorm';
import { Reserva } from './reserva.entity';
import { CrearReservaDto } from './dto/crear-reserva.dto';
import { ActualizarReservaDto } from './dto/actualizar-reserva.dto';
import { ConsultarDisponibilidadDto } from './dto/consultar-disponibilidad.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Mesa } from '../mesa/mesa.entity';
import { ReservasGateway } from './reservas.gateway';
import { HorarioAtencion } from '../horario-atencion/horario-atencion.entity';
import { ExcepcionHorario } from '../horario-atencion/excepcion-horario.entity';
import { NotificacionesService } from '../notificaciones/notificaciones.service';

@Injectable()
export class ReservasService {
  constructor(
    @InjectRepository(Reserva)
    private readonly reservasRepo: Repository<Reserva>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
    @InjectRepository(Mesa)
    private readonly mesasRepo: Repository<Mesa>,
    @InjectRepository(HorarioAtencion)
    private readonly horariosRepo: Repository<HorarioAtencion>,
    @InjectRepository(ExcepcionHorario)
    private readonly excepcionesRepo: Repository<ExcepcionHorario>,
    private readonly reservasGateway: ReservasGateway,
    private readonly notificaciones: NotificacionesService,
  ) {}

  async crear(dto: CrearReservaDto): Promise<Reserva> {
    let resultado: { guardada: Reserva; mesa: Mesa };
    try {
      resultado = await this.reservasRepo.manager.transaction(
        async (manager) => {
          const mesasRepo = manager.getRepository(Mesa);
          const reservasRepo = manager.getRepository(Reserva);
          const usuariosRepo = manager.getRepository(Usuario);
          // Bloquear la fila base sin relaciones: PostgreSQL no admite FOR
          // UPDATE sobre el lado nullable del LEFT JOIN que crea TypeORM.
          await manager.query(
            'SELECT id_mesa FROM mesa WHERE id_mesa = $1 FOR UPDATE',
            [dto.idMesa],
          );
          await this.liberarEstadosManualesVencidos(dto.idMesa, mesasRepo);
          const mesa = await mesasRepo.findOne({
            where: { id: dto.idMesa },
            relations: { restaurante: true },
          });
          if (!mesa) throw new NotFoundException('Mesa no encontrada');
          this.validarCapacidadYEstadoMesa(
            {
              ...mesa,
              estado: this.estadoMesaEnHorario(mesa, dto.fecha, dto.hora, 60),
            },
            dto.numeroPersonas,
          );
          if (
            (
              await this.bloqueosManualesEnHorario(
                [dto.idMesa], dto.fecha, dto.hora, 60,
                (sql, params) => manager.query(sql, params),
              )
            ).length
          ) {
            throw new BadRequestException(
              'La mesa está bloqueada manualmente en ese horario',
            );
          }

          const usuario = await usuariosRepo.findOne({
            where: { id: dto.idUsuario },
          });
          if (!usuario) throw new NotFoundException('Usuario no encontrado');

          const duracionMinutos = 60;
          await this.validarHorarioRestaurante(
            mesa.restaurante.id,
            dto.fecha,
            dto.hora,
            duracionMinutos,
          );
          if (
            await this.haySolapamiento(
              dto.idMesa,
              dto.fecha,
              dto.hora,
              duracionMinutos,
              undefined,
              reservasRepo,
            )
          ) {
            throw new BadRequestException(
              'La mesa no está disponible en la fecha y hora seleccionadas',
            );
          }

          const reserva = reservasRepo.create({
            ...dto,
            usuario,
            mesa,
            estado: 'pendiente',
            duracionMinutos,
          });
          return { guardada: await reservasRepo.save(reserva), mesa };
        },
      );
    } catch (error) {
      if (this.isSlotConflict(error)) {
        throw new BadRequestException(
          'La mesa no está disponible en la fecha y hora seleccionadas',
        );
      }
      throw error;
    }
    const { guardada, mesa } = resultado;

    // Emitir únicamente los datos necesarios para actualizar las interfaces.
    // No se expone la entidad completa (usuario, correo u otras relaciones).
    const payload = {
      id: guardada.id,
      idUsuario: dto.idUsuario,
      idMesa: dto.idMesa,
      idRestaurante: mesa.restaurante.id,
      fecha: guardada.fecha,
      hora: guardada.hora,
      duracionMinutos: guardada.duracionMinutos,
      numeroPersonas: guardada.numeroPersonas,
      estado: guardada.estado,
    };
    // La reserva ya fue confirmada en la base de datos. La notificación en
    // tiempo real no debe bloquear la respuesta HTTP al comensal.
    void this.reservasGateway.emitNuevaReserva(payload);

    return guardada;
  }

  async consultarDisponibilidad(dto: ConsultarDisponibilidadDto): Promise<{
    mesas: Array<{ idMesa: number; numeroMesa: string; capacidad: number }>;
  }> {
    await this.liberarEstadosManualesVencidos();
    await this.validarHorarioRestaurante(
      dto.idRestaurante,
      dto.fecha,
      dto.hora,
      dto.duracionMinutos,
    );

    const mesas = await this.mesasRepo.find({
      where: {
        restaurante: { id: dto.idRestaurante },
        estado: In(['libre', 'ocupada', 'reservada']),
        capacidad: MoreThanOrEqual(dto.numeroPersonas),
      },
      relations: { restaurante: true },
      order: { capacidad: 'ASC', id: 'ASC' },
    });
    const mesasDisponiblesPorEstado = mesas.filter(
      (mesa) =>
        this.estadoMesaEnHorario(
          mesa,
          dto.fecha,
          dto.hora,
          dto.duracionMinutos,
        ) === 'libre',
    );
    if (mesasDisponiblesPorEstado.length === 0) return { mesas: [] };

    const bloqueos = await this.bloqueosManualesEnHorario(
      mesasDisponiblesPorEstado.map((mesa) => mesa.id),
      dto.fecha, dto.hora, dto.duracionMinutos,
    );
    const idsBloqueadas = new Set(bloqueos.map((bloqueo) => bloqueo.id_mesa));

    const ocupadas = await this.consultaSolapamientos(
      dto.fecha,
      dto.hora,
      dto.duracionMinutos,
    )
      .select('reserva.id_mesa', 'idMesa')
      .andWhere('reserva.id_mesa IN (:...ids)', {
        ids: mesasDisponiblesPorEstado.map((mesa) => mesa.id),
      })
      .getRawMany<{ idMesa: number }>();
    const idsOcupadas = new Set(
      ocupadas.map((reserva) => Number(reserva.idMesa)),
    );

    return {
      mesas: mesasDisponiblesPorEstado
        .filter((mesa) => !idsOcupadas.has(mesa.id) && !idsBloqueadas.has(mesa.id))
        .map((mesa) => ({
          idMesa: mesa.id,
          numeroMesa: mesa.numeroMesa,
          capacidad: mesa.capacidad!,
        })),
    };
  }

  async consultarOcupacionRestaurante(
    idRestaurante: number,
    fecha: string,
    hora: string,
    duracionMinutos = 60,
  ): Promise<{
    fecha: string;
    hora: string;
    duracionMinutos: number;
    mesas: Array<{
      idMesa: number;
      numeroMesa: string;
      capacidad: number;
      estado: Mesa['estado'];
      disponible: boolean;
      bloqueoHora: string | null;
      reserva: null | {
        id: number;
        estado: string;
        fecha: string;
        hora: string;
        duracionMinutos: number;
        numeroPersonas: number;
        cliente: string;
      };
    }>;
  }> {
    await this.liberarEstadosManualesVencidos();
    const mesas = await this.mesasRepo.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
      order: { id: 'ASC' },
    });
    if (mesas.length === 0) {
      return { fecha, hora, duracionMinutos, mesas: [] };
    }

    const reservas = await this.consultaOcupacionEnInstante(fecha, hora)
      .leftJoinAndSelect('reserva.mesa', 'mesa')
      .leftJoinAndSelect('reserva.usuario', 'usuario')
      .andWhere('reserva.id_mesa IN (:...ids)', {
        ids: mesas.map((mesa) => mesa.id),
      })
      .orderBy('reserva.fecha', 'ASC')
      .addOrderBy('reserva.hora', 'ASC')
      .getMany();
    const reservaPorMesa = new Map<number, Reserva>();
    for (const reserva of reservas) {
      if (reserva.mesa && !reservaPorMesa.has(reserva.mesa.id)) {
        reservaPorMesa.set(reserva.mesa.id, reserva);
      }
    }

    const bloqueos = await this.bloqueosManualesEnHorario(
      mesas.map((mesa) => mesa.id), fecha, hora, 0,
    );
    const bloqueoPorMesa = new Map(bloqueos.map((bloqueo) => [bloqueo.id_mesa, bloqueo]));

    return {
      fecha,
      hora,
      duracionMinutos,
      mesas: mesas.map((mesa) => {
        const reserva = reservaPorMesa.get(mesa.id);
        const bloqueo = bloqueoPorMesa.get(mesa.id);
        const estadoBase = this.estadoMesaEnHorario(mesa, fecha, hora, 0);
        const estado = estadoBase === 'inactiva'
          ? 'inactiva' : bloqueo?.estado ?? estadoBase;
        const disponible = estado === 'libre' && !reserva;
        return {
          idMesa: mesa.id,
          numeroMesa: mesa.numeroMesa,
          capacidad: mesa.capacidad ?? 0,
          estado,
          disponible,
          bloqueoHora: estadoBase === 'inactiva' ? null : bloqueo?.hora ?? null,
          reserva: reserva
            ? {
                id: reserva.id,
                estado: reserva.estado,
                fecha: reserva.fecha,
                hora: reserva.hora,
                duracionMinutos: reserva.duracionMinutos,
                numeroPersonas: reserva.numeroPersonas,
                cliente:
                  `${reserva.usuario?.nombre ?? ''} ${reserva.usuario?.apellido ?? ''}`.trim(),
              }
            : null,
        };
      }),
    };
  }

  listarTodas(): Promise<Reserva[]> {
    return this.reservasRepo.find({
      relations: { usuario: true, mesa: { restaurante: true } },
    });
  }

  async buscarPorId(id: number): Promise<Reserva> {
    const reserva = await this.reservasRepo.findOne({
      where: { id },
      relations: { usuario: true, mesa: { restaurante: true } },
    });
    if (!reserva) throw new NotFoundException(`Reserva #${id} no encontrada`);
    return reserva;
  }

  async listarPorUsuario(
    idUsuario: number,
  ): Promise<Array<Reserva & { cancelarHasta: string }>> {
    const reservas = await this.reservasRepo.find({
      where: { usuario: { id: idUsuario } },
      relations: { mesa: { restaurante: true } },
    });
    return reservas.map((reserva) => ({
      ...reserva,
      cancelarHasta: new Date(this.limiteCancelacion(reserva)).toISOString(),
    }));
  }

  async listarPorRestaurante(idRestaurante: number): Promise<Reserva[]> {
    return this.reservasRepo.find({
      where: { mesa: { restaurante: { id: idRestaurante } } },
      relations: { usuario: true, mesa: true },
    });
  }

  async actualizar(id: number, dto: ActualizarReservaDto): Promise<Reserva> {
    const reservaInicial = await this.buscarPorId(id);
    const idMesaBloqueada = dto.idMesa ?? reservaInicial.mesa.id;
    let saved: Reserva;
    let changed = false;
    let nuevaNotificacion: Awaited<
      ReturnType<NotificacionesService['crearPorCambioDeReserva']>
    > | null = null;
    try {
      const resultado = await this.reservasRepo.manager.transaction(
        async (manager) => {
          const mesasRepo = manager.getRepository(Mesa);
          await manager.query(
            'SELECT id_mesa FROM mesa WHERE id_mesa = $1 FOR UPDATE',
            [idMesaBloqueada],
          );
          const mesaBloqueada = await mesasRepo.findOne({
            where: { id: idMesaBloqueada },
            relations: { restaurante: true },
          });
          if (!mesaBloqueada) throw new NotFoundException('Mesa no encontrada');

          await manager.query(
            'SELECT id_reserva FROM reservas WHERE id_reserva = $1 FOR UPDATE',
            [id],
          );
          const reserva = await manager.findOne(Reserva, {
            where: { id },
            relations: {
              usuario: true,
              mesa: { restaurante: true },
            },
          });
          if (!reserva)
            throw new NotFoundException(`Reserva #${id} no encontrada`);
          if (dto.idMesa === undefined && reserva.mesa.id !== idMesaBloqueada) {
            throw new BadRequestException(
              'La reserva cambió de mesa. Actualiza e intenta nuevamente.',
            );
          }
          const estadoAnterior = reserva.estado;

          if (dto.idMesa !== undefined) reserva.mesa = mesaBloqueada;
          if (dto.estado) reserva.estado = dto.estado;
          if (dto.fecha) reserva.fecha = dto.fecha;
          if (dto.hora) reserva.hora = dto.hora;
          if (dto.duracionMinutos !== undefined && dto.duracionMinutos !== 60) {
            throw new BadRequestException(
              'Las reservas duran exactamente 60 minutos',
            );
          }
          if (dto.duracionMinutos !== undefined)
            reserva.duracionMinutos = dto.duracionMinutos;
          if (dto.numeroPersonas) reserva.numeroPersonas = dto.numeroPersonas;
          if (dto.comentarios !== undefined)
            reserva.comentarios = dto.comentarios;

          if (['pendiente', 'confirmada'].includes(reserva.estado)) {
            const cambiaMesaUHorario =
              dto.idMesa !== undefined ||
              dto.fecha !== undefined ||
              dto.hora !== undefined ||
              dto.duracionMinutos !== undefined;
            this.validarCapacidadYEstadoMesa(
              {
                ...reserva.mesa,
                estado: this.estadoMesaEnHorario(
                  reserva.mesa,
                  reserva.fecha,
                  reserva.hora,
                  reserva.duracionMinutos,
                ),
              },
              reserva.numeroPersonas,
              cambiaMesaUHorario,
            );
            if (
              cambiaMesaUHorario &&
              (
                await this.bloqueosManualesEnHorario(
                  [reserva.mesa.id], reserva.fecha, reserva.hora,
                  reserva.duracionMinutos,
                  (sql, params) => manager.query(sql, params),
                )
              ).length
            ) {
              throw new BadRequestException(
                'La mesa está bloqueada manualmente en ese horario',
              );
            }
            await this.validarHorarioRestaurante(
              reserva.mesa.restaurante.id,
              reserva.fecha,
              reserva.hora,
              reserva.duracionMinutos,
            );
            if (
              await this.haySolapamiento(
                reserva.mesa.id,
                reserva.fecha,
                reserva.hora,
                reserva.duracionMinutos,
                reserva.id,
                manager.getRepository(Reserva),
              )
            ) {
              throw new BadRequestException(
                'La mesa no está disponible en la fecha y hora seleccionadas',
              );
            }
          }

          const reservaGuardada = await manager.save(Reserva, reserva);
          changed = estadoAnterior !== reservaGuardada.estado;
          const aviso =
            changed &&
            (reservaGuardada.estado === 'confirmada' ||
              reservaGuardada.estado === 'rechazada')
              ? await this.notificaciones.crearPorCambioDeReserva(
                  manager,
                  reservaGuardada,
                )
              : null;
          return { reservaGuardada, aviso };
        },
      );
      saved = resultado.reservaGuardada;
      nuevaNotificacion = resultado.aviso;
    } catch (error) {
      if (this.isSlotConflict(error)) {
        throw new BadRequestException(
          'La mesa no está disponible en la fecha y hora seleccionadas',
        );
      }
      throw error;
    }
    if (nuevaNotificacion)
      void this.notificaciones.enviarPush(nuevaNotificacion);
    if (changed)
      await this.reservasGateway.emitActualizacionReserva(
        saved.id,
        saved.estado,
        saved.mesa.restaurante.id,
        saved.usuario.id,
      );
    return saved;
  }

  async eliminar(id: number): Promise<void> {
    const reserva = await this.buscarPorId(id);
    reserva.estado = 'cancelada';
    await this.reservasRepo.save(reserva);
  }

  async cancelarPorUsuario(
    id: number,
    idUsuario: number,
  ): Promise<{ id: number; estado: string }> {
    const cancelada = await this.reservasRepo.manager.transaction(async (manager) => {
      await manager.query(
        'SELECT id_reserva FROM reservas WHERE id_reserva = $1 FOR UPDATE',
        [id],
      );
      const actual = await manager.findOne(Reserva, {
        where: { id },
        relations: { usuario: true, mesa: { restaurante: true } },
      });
      if (!actual || actual.usuario.id !== idUsuario) {
        throw new NotFoundException('Reserva no encontrada');
      }
      if (!['pendiente', 'confirmada'].includes(actual.estado)) {
        throw new BadRequestException('Esta reserva ya no se puede cancelar');
      }
      if (Date.now() >= this.limiteCancelacion(actual)) {
        throw new BadRequestException(
          'Solo puedes cancelar hasta 15 minutos antes de la reserva',
        );
      }
      actual.estado = 'cancelada';
      await manager.save(Reserva, actual);
      return {
        id: actual.id,
        estado: actual.estado,
        idRestaurante: actual.mesa.restaurante.id,
      };
    });

    await this.reservasGateway.emitActualizacionReserva(
      cancelada.id,
      cancelada.estado,
      cancelada.idRestaurante,
      idUsuario,
    );
    return { id: cancelada.id, estado: cancelada.estado };
  }

  private limiteCancelacion(reserva: Reserva): number {
    const zonaHoraria = reserva.mesa.restaurante.zonaHoraria || 'America/La_Paz';
    return (
      this.instanteEnZonaHoraria(reserva.fecha, reserva.hora, zonaHoraria).getTime() -
      15 * 60 * 1000
    );
  }

  private isSlotConflict(error: unknown): boolean {
    const dbError = error as {
      code?: string;
      constraint?: string;
      driverError?: { code?: string; constraint?: string };
    };
    const cause = dbError?.driverError ?? dbError;
    return (
      (cause?.code === '23P01' &&
        cause?.constraint === 'ex_reserva_mesa_intervalo_activo') ||
      (cause?.code === '23505' &&
        cause?.constraint === 'uq_reserva_mesa_horario_activa')
    );
  }

  private async haySolapamiento(
    idMesa: number,
    fecha: string,
    hora: string,
    duracionMinutos: number,
    excluirId?: number,
    reservasRepo: Repository<Reserva> = this.reservasRepo,
  ): Promise<boolean> {
    const consulta = this.consultaSolapamientos(
      fecha,
      hora,
      duracionMinutos,
      reservasRepo,
    ).andWhere('reserva.id_mesa = :idMesa', { idMesa });
    if (excluirId !== undefined) {
      consulta.andWhere('reserva.id_reserva <> :excluirId', { excluirId });
    }
    return (await consulta.getCount()) > 0;
  }

  private async bloqueosManualesEnHorario(
    idsMesa: number[],
    fecha: string,
    hora: string,
    duracionMinutos: number,
    query: (sql: string, parameters: unknown[]) => Promise<Array<{
      id_mesa: number;
      estado: 'ocupada' | 'reservada';
      hora: string;
    }>> = (sql, parameters) => this.mesasRepo.query(sql, parameters),
  ) {
    if (!idsMesa.length) return [];
    const inicio = 'CAST($2 AS date) + CAST($3 AS time)';
    return query(
      `SELECT id_mesa, estado, to_char(hora, 'HH24:MI') AS hora
       FROM mesa_bloqueo_horario
       WHERE id_mesa = ANY($1::int[])
         AND fecha + hora ${duracionMinutos === 0 ? '<=' : '<'}
           ${inicio} + ($4 * INTERVAL '1 minute')
         AND fecha + hora + INTERVAL '60 minutes' > ${inicio}`,
      [idsMesa, fecha, hora, duracionMinutos],
    );
  }

  private consultaSolapamientos(
    fecha: string,
    hora: string,
    duracionMinutos: number,
    reservasRepo: Repository<Reserva> = this.reservasRepo,
  ): SelectQueryBuilder<Reserva> {
    return reservasRepo
      .createQueryBuilder('reserva')
      .where("reserva.estado IN ('pendiente', 'confirmada')")
      .andWhere(
        `reserva.fecha + reserva.hora - (30 * INTERVAL '1 minute') <
         CAST(:fecha AS date) + CAST(:hora AS time) +
         (:duracionMinutos * INTERVAL '1 minute')`,
        { fecha, hora, duracionMinutos },
      )
      .andWhere(
        `reserva.fecha + reserva.hora +
         (reserva.duracion_minutos * INTERVAL '1 minute') >
         CAST(:fecha AS date) + CAST(:hora AS time)`,
        { fecha, hora },
      );
  }

  /**
   * La vista de mesas representa la ocupación en un instante concreto. Una
   * reserva empieza a bloquear 30 minutos antes de su hora y deja de bloquear
   * al llegar a su hora de fin (intervalo [inicio - 30 min, fin)).
   */
  private consultaOcupacionEnInstante(
    fecha: string,
    hora: string,
    reservasRepo: Repository<Reserva> = this.reservasRepo,
  ): SelectQueryBuilder<Reserva> {
    return reservasRepo
      .createQueryBuilder('reserva')
      .where("reserva.estado IN ('pendiente', 'confirmada')")
      .andWhere(
        `reserva.fecha + reserva.hora - (30 * INTERVAL '1 minute') <=
         CAST(:fecha AS date) + CAST(:hora AS time)`,
        { fecha, hora },
      )
      .andWhere(
        `reserva.fecha + reserva.hora +
         (reserva.duracion_minutos * INTERVAL '1 minute') >
         CAST(:fecha AS date) + CAST(:hora AS time)`,
        { fecha, hora },
      );
  }

  private validarCapacidadYEstadoMesa(
    mesa: Mesa,
    numeroPersonas: number,
    requiereMesaLibre = true,
  ): void {
    if (
      mesa.estado === 'inactiva' ||
      (requiereMesaLibre && mesa.estado !== 'libre')
    ) {
      throw new BadRequestException('La mesa seleccionada no está disponible');
    }
    if (!mesa.capacidad || numeroPersonas > mesa.capacidad) {
      throw new BadRequestException(
        `La mesa seleccionada tiene capacidad para ${mesa.capacidad ?? 0} personas`,
      );
    }
  }

  private minutos(hora: string): number {
    const [horas, minutos] = hora.split(':').map(Number);
    return horas * 60 + minutos;
  }

  private async liberarEstadosManualesVencidos(
    idMesa?: number,
    mesasRepo: Repository<Mesa> = this.mesasRepo,
  ): Promise<void> {
    await mesasRepo.update(
      {
        ...(idMesa === undefined ? {} : { id: idMesa }),
        estado: In(['ocupada', 'reservada']),
        estadoHasta: Or(IsNull(), LessThanOrEqual(new Date())),
      },
      { estado: 'libre', estadoHasta: null },
    );
  }

  private estadoMesaEnHorario(
    mesa: Mesa,
    fecha: string,
    hora: string,
    duracionMinutos: number,
  ): Mesa['estado'] {
    if (mesa.estado === 'inactiva' || mesa.estado === 'libre') {
      return mesa.estado;
    }
    if (!mesa.estadoHasta) return 'libre';

    const zonaHoraria = mesa.restaurante?.zonaHoraria || 'America/La_Paz';
    const inicioHorario = this.instanteEnZonaHoraria(fecha, hora, zonaHoraria);
    const finHorario = new Date(
      inicioHorario.getTime() + duracionMinutos * 60000,
    );
    const finEstado = new Date(mesa.estadoHasta).getTime();
    const inicioEstado = finEstado - 60 * 60000;
    const seCruzan =
      duracionMinutos === 0
        ? inicioHorario.getTime() >= inicioEstado &&
          inicioHorario.getTime() < finEstado
        : inicioHorario.getTime() < finEstado &&
          finHorario.getTime() > inicioEstado;
    return seCruzan ? mesa.estado : 'libre';
  }

  private instanteEnZonaHoraria(
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

  private async validarHorarioRestaurante(
    idRestaurante: number,
    fecha: string,
    hora: string,
    duracionMinutos: number,
  ): Promise<void> {
    const inicio = this.minutos(hora);
    const fin = inicio + duracionMinutos;
    if (fin > 24 * 60) {
      throw new BadRequestException(
        'La reserva no puede extenderse al día siguiente.',
      );
    }

    const excepcion = await this.excepcionesRepo.findOne({
      where: { restaurante: { id: idRestaurante }, fecha },
    });
    if (excepcion?.cerrado) {
      throw new BadRequestException(
        excepcion.motivo || 'El restaurante está cerrado en esa fecha.',
      );
    }

    let franjas: Array<{ horaInicio: string; horaFin: string }>;
    if (excepcion?.horaInicio && excepcion.horaFin) {
      franjas = [
        {
          horaInicio: excepcion.horaInicio,
          horaFin: excepcion.horaFin,
        },
      ];
    } else {
      const diaSemana = (new Date(`${fecha}T00:00:00Z`).getUTCDay() + 6) % 7;
      franjas = await this.horariosRepo.find({
        where: { restaurante: { id: idRestaurante }, diaSemana },
      });
    }

    const dentroDeHorario = franjas.some(
      (franja) =>
        inicio >= this.minutos(franja.horaInicio) &&
        fin <= this.minutos(franja.horaFin),
    );
    if (!dentroDeHorario) {
      throw new BadRequestException(
        'La reserva queda fuera del horario de atención.',
      );
    }
  }
}
