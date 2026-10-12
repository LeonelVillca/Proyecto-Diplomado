import { BadRequestException, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { BCRYPT_COST } from '../../../common/constants/security.constants';
import { createHash } from 'crypto';
import { DataSource } from 'typeorm';
import { CuentaAuth } from '../../cuentas-auth/cuenta-auth.entity';
import { InvitacionToken } from '../../invitacion-token/invitacion-token.entity';
import { CrearContrasenaDto } from '../dto/crear-contrasena.dto';

@Injectable()
export class ContrasenasService {
  // Recibe la conexion usada para crear contrasenas en una transaccion.
  constructor(private readonly dataSource: DataSource) {}

  // Crea la contrasena al consumir una invitacion valida.
  async crearContrasena(dto: CrearContrasenaDto): Promise<{ mensaje: string }> {
    const tokenHash = createHash('sha256').update(dto.token).digest('hex');
    await this.dataSource.transaction(async (manager) => {
      // Bloquea el token sin unir la relacion opcional.
      const filasBloqueadas: Array<{ id_token: number }> = await manager.query(
        `SELECT id_token FROM invitacion_token
         WHERE token = $1 AND tipo = $2 FOR UPDATE`,
        [tokenHash, 'invitacion'],
      );
      if (!filasBloqueadas.length) {
        throw new BadRequestException('El token es inválido o no existe.');
      }
      const invitacion = await manager.findOne(InvitacionToken, {
        where: { token: tokenHash, tipo: 'invitacion' },
        relations: { usuario: true },
      });

      if (!invitacion) {
        throw new BadRequestException('El token es inválido o no existe.');
      }
      if (invitacion.usado) {
        throw new BadRequestException('El token ya ha sido utilizado.');
      }
      if (invitacion.fechaExpiracion < new Date()) {
        throw new BadRequestException(
          'El token ha expirado. Por favor, solicita uno nuevo.',
        );
      }

      const cuentaRepo = manager.getRepository(CuentaAuth);
      let cuenta = await cuentaRepo.findOne({
        where: { usuario: { id: invitacion.usuario.id } },
        lock: { mode: 'pessimistic_write' },
      });
      if (cuenta?.passwordHash) {
        throw new BadRequestException('La cuenta ya tiene contraseña creada.');
      }
      const passwordHash = await bcrypt.hash(dto.password, BCRYPT_COST);
      if (!cuenta) {
        cuenta = cuentaRepo.create({
          usuario: { id: invitacion.usuario.id },
          passwordHash,
        });
      } else {
        cuenta.passwordHash = passwordHash;
      }
      await cuentaRepo.save(cuenta);
      invitacion.usado = true;
      await manager.save(invitacion);
    });

    return { mensaje: 'Contraseña creada exitosamente' };
  }
}
