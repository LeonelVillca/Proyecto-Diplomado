import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CategoriaSoporte } from './categoria-soporte.entity';
import { CrearCategoriaSoporteDto } from './dto/crear-categoria-soporte.dto';
import { ActualizarCategoriaSoporteDto } from './dto/actualizar-categoria-soporte.dto';

@Injectable()
export class CategoriaSoporteService implements OnModuleInit {
  constructor(
    @InjectRepository(CategoriaSoporte)
    private readonly categoriaRepository: Repository<CategoriaSoporte>,
  ) {}

  async onModuleInit() {
    const count = await this.categoriaRepository.count();
    if (count === 0) {
      const defaultCategorias = [
        'Problemas con mi cuenta',
        'Problemas con una reserva',
        'Problemas con una reseña',
        'Reportar un restaurante',
        'Sugerencias y otros',
      ];
      for (const nombre of defaultCategorias) {
        await this.categoriaRepository.save(this.categoriaRepository.create({ nombre }));
      }
      console.log('Seeded categorías de soporte por defecto.');
    }
  }

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