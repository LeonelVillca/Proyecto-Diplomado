import { BadRequestException, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomInt, timingSafeEqual } from 'crypto';
import { DataSource } from 'typeorm';
import { UsuariosService } from '../../usuarios/usuarios.service';
import { CuentasAuthService } from '../../cuentas-auth/cuentas-auth.service';
import { CuentaAuth } from '../../cuentas-auth/cuenta-auth.entity';
import { InvitacionToken } from '../../invitacion-token/invitacion-token.entity';
import { MailService } from '../../mail/mail.service';
import { pinHmacSecret } from '../../../core/config/security.config';
import {
  SolicitarRecuperacionDto,
  RestablecerPasswordDto,
  VerificarPinDto,
} from '../dto/recuperar-password.dto';

@Injectable()
export class RecuperacionService {
  // Recibe los servicios para recuperar una cuenta.
  constructor(
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
    private readonly dataSource: DataSource,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) {}

  // Calcula el hash del PIN de recuperacion.
  private hashPin(idUsuario: number, pin: string): string {
    return createHmac('sha256', pinHmacSecret(this.configService))
      .update(`recuperacion:${idUsuario}:${pin}`)
      .digest('hex');
  }

  // Genera y envia un PIN si la cuenta puede recuperarse.
  async solicitarRecuperacion(
    dto: SolicitarRecuperacionDto,
  ): Promise<{ mensaje: string }> {
    const usuario = await this.usuariosService.buscarPorCorreo(
      dto.correo.trim().toLowerCase(),
    );
    const respuesta = {
      mensaje:
        'Si el correo existe en el sistema, recibirás un código PIN en los próximos minutos.',
    };
    if (!usuario || usuario.estado !== 'activo') return respuesta;
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta?.estado) return respuesta;
    const pin = randomInt(100000, 1000000).toString();
    const created = await this.dataSource.transaction(async (manager) => {
      // Serializa solicitudes de recuperacion de la cuenta.
      await manager.findOne(CuentaAuth, {
        where: { id: cuenta.id },
        lock: { mode: 'pessimistic_write' },
      });
      const repo = manager.getRepository(InvitacionToken);
      const last = await repo.findOne({
        where: { usuario: { id: usuario.id }, tipo: 'recuperacion' },
        order: { id: 'DESC' },
      });
      if (last && Date.now() - last.fechaCreacion.getTime() < 60_000)
        return false;
      await repo.update(
        { usuario: { id: usuario.id }, tipo: 'recuperacion', usado: false },
        { usado: true },
      );
      await repo.save(
        repo.create({
          usuario: { id: usuario.id },
          token: this.hashPin(usuario.id, pin),
          tipo: 'recuperacion',
          fechaExpiracion: new Date(Date.now() + 15 * 60_000),
        }),
      );
      return true;
    });
    if (created)
      await this.mailService.enviarRecuperacionPassword(usuario.correo, pin);
    return respuesta;
  }

  // Comprueba si el PIN recibido sigue siendo valido.
  async verificarPinRecuperacion(
    dto: VerificarPinDto,
  ): Promise<{ valido: boolean }> {
    await this.validarRecuperacion(dto);
    return { valido: true };
  }

  // Cambia la contrasena y consume el PIN.
  async restablecerPassword(
    dto: RestablecerPasswordDto,
  ): Promise<{ mensaje: string }> {
    await this.validarRecuperacion(dto, dto.nuevaContrasena);
    return { mensaje: 'Contraseña actualizada exitosamente' };
  }

  // Valida el PIN y aplica el cambio dentro de una transaccion.
  private async validarRecuperacion(
    dto: VerificarPinDto,
    password?: string,
  ): Promise<void> {
    const usuario = await this.usuariosService.buscarPorCorreo(
      dto.correo.trim().toLowerCase(),
    );
    if (!usuario || usuario.estado !== 'activo')
      throw new BadRequestException('El PIN es inválido o ha expirado.');
    const accepted = await this.dataSource.transaction(async (manager) => {
      const cuenta = await manager.findOne(CuentaAuth, {
        where: { usuario: { id: usuario.id } },
        lock: { mode: 'pessimistic_write' },
      });
      if (!cuenta?.estado) return false;
      const repo = manager.getRepository(InvitacionToken);
      const record = await repo.findOne({
        where: {
          usuario: { id: usuario.id },
          tipo: 'recuperacion',
          usado: false,
        },
        order: { id: 'DESC' },
        lock: { mode: 'pessimistic_write' },
      });
      if (
        !record ||
        record.fechaExpiracion <= new Date() ||
        record.intentosVerificacion >= 5
      )
        return false;
      const stored = Buffer.from(record.token);
      const supplied = Buffer.from(this.hashPin(usuario.id, dto.pin));
      if (
        stored.length !== supplied.length ||
        !timingSafeEqual(stored, supplied)
      ) {
        record.intentosVerificacion++;
        if (record.intentosVerificacion >= 5) record.usado = true;
        await repo.save(record);
        return false;
      }
      if (password !== undefined) {
        await manager.update(CuentaAuth, cuenta.id, {
          passwordHash: await bcrypt.hash(password, 12),
          intentosFallidos: 0,
          sessionVersion: () => 'session_version + 1',
        });
        record.usado = true;
        await repo.save(record);
      }
      return true;
    });
    if (!accepted)
      throw new BadRequestException('El PIN es inválido o ha expirado.');
  }
}
