import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { Repository } from 'typeorm';
import { CuentaAuth } from './cuenta-auth.entity';
import { CrearCuentaAuthDto } from './dto/crear-cuenta-auth.dto';
import { ActualizarCuentaAuthDto } from './dto/actualizar-cuenta-auth.dto';

@Injectable()
export class CuentasAuthService {
  constructor(
    @InjectRepository(CuentaAuth)
    private readonly cuentaAuthRepository: Repository<CuentaAuth>,
  ) {}

  async listar(): Promise<CuentaAuth[]> {
    return this.cuentaAuthRepository.find({ relations: { usuario: true } });
  }

  buscarPorUsuario(idUsuario: number): Promise<CuentaAuth | null> {
    return this.cuentaAuthRepository.findOne({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true },
    });
  }

  async crear(dto: CrearCuentaAuthDto): Promise<CuentaAuth> {
    const existente = await this.buscarPorUsuario(dto.idUsuario);
    if (existente) {
      throw new ConflictException(
        'El usuario ya tiene una cuenta de autenticación registrada',
      );
    }

    const cuenta = this.cuentaAuthRepository.create({
      usuario: { id: dto.idUsuario } as never,
      passwordHash: dto.password ? await bcrypt.hash(dto.password, 10) : null,
    });
    return this.cuentaAuthRepository.save(cuenta);
  }

  async asegurarCuenta(
    idUsuario: number,
    password?: string,
  ): Promise<CuentaAuth> {
    let cuenta = await this.buscarPorUsuario(idUsuario);
    if (!cuenta) {
      cuenta = await this.crear({ idUsuario, password });
    } else if (password && !cuenta.passwordHash) {
      cuenta.passwordHash = await bcrypt.hash(password, 10);
      cuenta = await this.cuentaAuthRepository.save(cuenta);
    }
    return cuenta;
  }

  async registrarUltimoIngreso(idUsuario: number): Promise<void> {
    await this.cuentaAuthRepository.update({ usuario: { id: idUsuario } }, { ultimoIngreso: new Date(), intentosFallidos: 0 });
  }

  async incrementarIntentosFallidos(idCuenta: number): Promise<void> {
    await this.cuentaAuthRepository.increment({ id: idCuenta }, 'intentosFallidos', 1);
  }

  async revocarSesiones(idUsuario: number): Promise<void> {
    await this.cuentaAuthRepository.increment({ usuario: { id: idUsuario } }, 'sessionVersion', 1);
  }

  async actualizar(
    idCuenta: number,
    dto: ActualizarCuentaAuthDto,
  ): Promise<CuentaAuth> {
    const cuenta = await this.cuentaAuthRepository.findOne({
      where: { id: idCuenta },
    });
    if (!cuenta) {
      throw new NotFoundException('Cuenta de autenticación no encontrada');
    }

    if (dto.password !== undefined) {
      cuenta.passwordHash = await bcrypt.hash(dto.password, 10);
      cuenta.intentosFallidos = 0;
    }
    if (dto.estado !== undefined) {
      cuenta.estado = dto.estado;
    }
    await this.cuentaAuthRepository.update(idCuenta, {
      passwordHash: cuenta.passwordHash,
      estado: cuenta.estado,
      intentosFallidos: cuenta.intentosFallidos,
      sessionVersion: () => 'session_version + 1',
    });
    return this.cuentaAuthRepository.findOneByOrFail({ id: idCuenta });
  }
}
