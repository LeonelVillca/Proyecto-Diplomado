import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OauthCuenta } from './oauth-cuenta.entity';
import { CrearOauthCuentaDto } from './dto/crear-oauth-cuenta.dto';
import { ActualizarOauthCuentaDto } from './dto/actualizar-oauth-cuenta.dto';

@Injectable()
export class OauthCuentasService {
  constructor(
    @InjectRepository(OauthCuenta)
    private readonly oauthCuentaRepository: Repository<OauthCuenta>,
  ) {}

  listar(): Promise<OauthCuenta[]> {
    return this.oauthCuentaRepository.find({ relations: { usuario: true } });
  }

  buscarPorUsuarioYProveedor(
    idUsuario: number,
    proveedor: string,
  ): Promise<OauthCuenta | null> {
    return this.oauthCuentaRepository.findOne({
      where: { usuario: { id: idUsuario }, proveedor },
    });
  }

  async crear(dto: CrearOauthCuentaDto): Promise<OauthCuenta> {
    const existente = await this.buscarPorUsuarioYProveedor(
      dto.idUsuario,
      dto.proveedor,
    );
    if (existente) {
      throw new ConflictException(
        'El usuario ya tiene una cuenta OAuth para ese proveedor',
      );
    }

    const cuenta = this.oauthCuentaRepository.create({
      usuario: { id: dto.idUsuario } as never,
      proveedor: dto.proveedor,
      proveedorId: dto.proveedorId,
      emailVerificado: dto.emailVerificado ?? false,
    });
    return this.oauthCuentaRepository.save(cuenta);
  }

  async vincularOCrear(dto: CrearOauthCuentaDto): Promise<OauthCuenta> {
    const existente = await this.buscarPorUsuarioYProveedor(
      dto.idUsuario,
      dto.proveedor,
    );
    if (existente) {
      existente.proveedorId = dto.proveedorId;
      if (dto.emailVerificado !== undefined) {
        existente.emailVerificado = dto.emailVerificado;
      }
      return this.oauthCuentaRepository.save(existente);
    }
    return this.crear(dto);
  }

  async actualizar(
    idOauth: number,
    dto: ActualizarOauthCuentaDto,
  ): Promise<OauthCuenta> {
    const cuenta = await this.oauthCuentaRepository.findOne({
      where: { id: idOauth },
    });
    if (!cuenta) {
      throw new NotFoundException('Cuenta OAuth no encontrada');
    }

    if (dto.proveedor !== undefined) {
      cuenta.proveedor = dto.proveedor;
    }
    if (dto.proveedorId !== undefined) {
      cuenta.proveedorId = dto.proveedorId;
    }
    if (dto.emailVerificado !== undefined) {
      cuenta.emailVerificado = dto.emailVerificado;
    }
    return this.oauthCuentaRepository.save(cuenta);
  }
}