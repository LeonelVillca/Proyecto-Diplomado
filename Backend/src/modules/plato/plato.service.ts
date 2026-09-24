import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Plato } from './plato.entity';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Menu } from '../menu/menu.entity';

@Injectable()
export class PlatoService {
  constructor(
    @InjectRepository(Plato)
    private readonly platoRepository: Repository<Plato>,
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
  ) {}

  async crear(dto: CrearPlatoDto): Promise<Plato> {
    const menu = await this.menuRepository.findOneBy({ id: dto.idMenu });
    if (!menu) {
      throw new NotFoundException(`Menú con id ${dto.idMenu} no encontrado`);
    }

    const plato = this.platoRepository.create({
      nombre: dto.nombre,
      precio: dto.precio,
      descripcion: dto.descripcion,
      fotoUrl: dto.fotoUrl,
      disponible: dto.disponible,
      menu,
    });
    return this.platoRepository.save(plato);
  }

  listarTodos(): Promise<Plato[]> {
    return this.platoRepository.find({ relations: { menu: true } });
  }

  async buscarPorId(id: number): Promise<Plato> {
    const plato = await this.platoRepository.findOne({
      where: { id },
      relations: { menu: true },
    });
    if (!plato) {
      throw new NotFoundException(`Plato con id ${id} no encontrado`);
    }
    return plato;
  }

  listarPorMenu(idMenu: number): Promise<Plato[]> {
    return this.platoRepository.find({
      where: { menu: { id: idMenu } },
      relations: { menu: true },
    });
  }

  async actualizar(id: number, dto: ActualizarPlatoDto): Promise<Plato> {
    const plato = await this.buscarPorId(id);
    Object.assign(plato, dto);
    return this.platoRepository.save(plato);
  }

  async eliminar(id: number): Promise<void> {
    const plato = await this.buscarPorId(id);
    await this.platoRepository.delete(plato.id);
  }
}
