import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Reporte } from './reporte.entity';
import { CrearReporteDto } from './dto/crear-reporte.dto';
import { ActualizarReporteDto } from './dto/actualizar-reporte.dto';
import { Usuario } from '../usuarios/usuario.entity';

@Injectable()
export class ReportesService {
  constructor(
    @InjectRepository(Reporte)
    private readonly reporteRepository: Repository<Reporte>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async crear(dto: CrearReporteDto): Promise<Reporte> {
    const usuario = await this.usuarioRepository.findOneBy({ id: dto.idUsuario });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${dto.idUsuario} no encontrado`);
    }

    const { idUsuario, ...datos } = dto;
    const reporte = this.reporteRepository.create({ ...datos, usuario });
    return this.reporteRepository.save(reporte);
  }

  listarTodos(): Promise<Reporte[]> {
    return this.reporteRepository.find({
      relations: { usuario: true },
      order: { id: 'DESC' },
    });
  }

  async buscarPorId(id: number): Promise<Reporte> {
    const reporte = await this.reporteRepository.findOne({
      where: { id },
      relations: { usuario: true },
    });
    if (!reporte) {
      throw new NotFoundException(`Reporte con id ${id} no encontrado`);
    }
    return reporte;
  }

  listarPorUsuario(idUsuario: number): Promise<Reporte[]> {
    return this.reporteRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true },
      order: { id: 'DESC' },
    });
  }

  async actualizar(id: number, dto: ActualizarReporteDto): Promise<Reporte> {
    const reporte = await this.buscarPorId(id);
    Object.assign(reporte, dto);
    return this.reporteRepository.save(reporte);
  }

  async eliminar(id: number): Promise<void> {
    const reporte = await this.buscarPorId(id);
    await this.reporteRepository.delete(reporte.id);
  }
}