import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { App, cert, getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { EntityManager, IsNull, Repository } from 'typeorm';
import { Reserva } from '../reservas/reserva.entity';
import { Notificacion } from './notificacion.entity';
import { DispositivoPush } from './dispositivo-push.entity';

@Injectable()
export class NotificacionesService {
  private readonly logger = new Logger(NotificacionesService.name);
  private readonly firebaseApp: App | null;

  constructor(
    @InjectRepository(Notificacion)
    private readonly notificacionesRepo: Repository<Notificacion>,
    @InjectRepository(DispositivoPush)
    private readonly dispositivosRepo: Repository<DispositivoPush>,
    configService: ConfigService,
  ) {
    if (getApps().length > 0) {
      this.firebaseApp = getApp();
      return;
    }
    const projectId = configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = configService.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = configService.get<string>('FIREBASE_PRIVATE_KEY');
    this.firebaseApp =
      projectId && clientEmail && privateKey
        ? initializeApp({
            credential: cert({
              projectId,
              clientEmail,
              privateKey: privateKey.replace(/\\n/g, '\n'),
            }),
          })
        : null;
    if (!this.firebaseApp) {
      this.logger.warn(
        'Push no configurado; los avisos seguirán disponibles en la app.',
      );
    }
  }

  async listar(idUsuario: number) {
    const [items, noLeidas] = await Promise.all([
      this.notificacionesRepo.find({
        where: { usuario: { id: idUsuario } },
        relations: { reserva: true },
        order: { creadaAt: 'DESC' },
        take: 50,
      }),
      this.notificacionesRepo.count({
        where: { usuario: { id: idUsuario }, leidaAt: IsNull() },
      }),
    ]);
    return {
      noLeidas,
      items: items.map((item) => ({
        id: item.id,
        tipo: item.tipo,
        titulo: item.titulo,
        mensaje: item.mensaje,
        idReserva: item.reserva?.id ?? null,
        creadaAt: item.creadaAt,
        leidaAt: item.leidaAt,
      })),
    };
  }

  async marcarLeida(idUsuario: number, id: string): Promise<void> {
    const result = await this.notificacionesRepo
      .createQueryBuilder()
      .update(Notificacion)
      .set({ leidaAt: new Date() })
      .where('id_notificacion = :id', { id })
      .andWhere('id_usuario = :idUsuario', { idUsuario })
      .execute();
    if (!result.affected)
      throw new NotFoundException('Notificación no encontrada');
  }

  async registrarDispositivo(
    idUsuario: number,
    token: string,
    plataforma: 'android' | 'ios',
  ): Promise<void> {
    await this.dispositivosRepo.query(
      `INSERT INTO dispositivo_push (id_usuario, token, plataforma)
       VALUES ($1, $2, $3)
       ON CONFLICT (token) DO UPDATE SET
         id_usuario = EXCLUDED.id_usuario,
         plataforma = EXCLUDED.plataforma,
         actualizado_at = now()`,
      [idUsuario, token, plataforma],
    );
  }

  async desregistrarDispositivo(
    idUsuario: number,
    token: string,
  ): Promise<void> {
    await this.dispositivosRepo
      .createQueryBuilder()
      .delete()
      .from(DispositivoPush)
      .where('id_usuario = :idUsuario AND token = :token', { idUsuario, token })
      .execute();
  }

  async crearPorCambioDeReserva(
    manager: EntityManager,
    reserva: Reserva,
  ): Promise<Notificacion> {
    const confirmada = reserva.estado === 'confirmada';
    const restaurante = reserva.mesa.restaurante.nombre;
    return manager.save(
      manager.create(Notificacion, {
        usuario: reserva.usuario,
        reserva,
        tipo: confirmada ? 'reserva_confirmada' : 'reserva_rechazada',
        titulo: confirmada ? 'Reserva confirmada' : 'Reserva rechazada',
        mensaje: confirmada
          ? `Tu reserva en ${restaurante} para el ${reserva.fecha} a las ${reserva.hora} fue confirmada.`
          : `Tu reserva en ${restaurante} para el ${reserva.fecha} a las ${reserva.hora} fue rechazada.`,
        leidaAt: null,
      }),
    );
  }

  async enviarPush(notificacion: Notificacion): Promise<void> {
    if (!this.firebaseApp) return;
    try {
      const dispositivos = await this.dispositivosRepo.find({
        where: { usuario: { id: notificacion.usuario.id } },
        take: 500,
      });
      if (dispositivos.length === 0) return;
      const respuesta = await getMessaging(
        this.firebaseApp,
      ).sendEachForMulticast({
        tokens: dispositivos.map((device) => device.token),
        notification: {
          title: notificacion.titulo,
          body: notificacion.mensaje,
        },
        data: {
          tipo: notificacion.tipo,
          idReserva: String(notificacion.reserva?.id ?? ''),
          idNotificacion: notificacion.id,
        },
      });
      const invalidos = respuesta.responses.flatMap((item, index) =>
        item.error?.code === 'messaging/registration-token-not-registered' ||
        item.error?.code === 'messaging/invalid-registration-token'
          ? [dispositivos[index].token]
          : [],
      );
      if (invalidos.length > 0) {
        await this.dispositivosRepo
          .createQueryBuilder()
          .delete()
          .from(DispositivoPush)
          .where('token IN (:...invalidos)', { invalidos })
          .execute();
      }
      if (respuesta.failureCount > 0) {
        this.logger.warn(
          `No se entregaron ${respuesta.failureCount} avisos push`,
        );
      }
    } catch (error) {
      this.logger.error('No se pudo enviar el aviso push', error);
    }
  }
}
