import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CategoriaSoporte } from './categoria-soporte.entity';
import { CrearCategoriaSoporteDto } from './dto/crear-categoria-soporte.dto';
import { ActualizarCategoriaSoporteDto } from './dto/actualizar-categoria-soporte.dto';

@Injectable()
export class CategoriaSoporteService {
  constructor(
    @InjectRepository(CategoriaSoporte)
    private readonly categoriaRepository: Repository<CategoriaSoporte>,
  ) {}

  crear(dto: CrearCategoriaSoporteDto): Promise<CategoriaSoporte> {
    const categoria = this.categoriaRepository.create(dto);
    return this.categoriaRepository.save(categoria);
  }

  listarTodas(): Promise<CategoriaSoporte[]> {
    return this.categoriaRepository.find({ order: { id: 'ASC' } });
  }

  async buscarPorId(id: number): Promise<CategoriaSoporte> {
    const categoria = await this.categoriaRepository.findOneBy({ id });
    if (!categoria) {
      throw new NotFoundException(`Categoría de soporte con id ${id} no encontrada`);
    }
    return categoria;
  }

  async actualizar(id: number, dto: ActualizarCategoriaSoporteDto): Promise<CategoriaSoporte> {
    const categoria = await this.buscarPorId(id);
    Object.assign(categoria, dto);
    return this.categoriaRepository.save(categoria);
  }

  async eliminar(id: number): Promise<void> {
    const categoria = await this.buscarPorId(id);
    await this.categoriaRepository.delete(categoria.id);
  }
}