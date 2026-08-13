import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Menu } from './menu.entity';
import { CrearMenuDto } from './dto/crear-menu.dto';
import { ActualizarMenuDto } from './dto/actualizar-menu.dto';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class MenuService {
  constructor(
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
  ) {}

  async crear(dto: CrearMenuDto): Promise<Menu> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${dto.idRestaurante} no encontrado`);
    }

    const { idRestaurante, ...datos } = dto;
    const menu = this.menuRepository.create({ ...datos, restaurante });
    return this.menuRepository.save(menu);
  }

  listarTodos(): Promise<Menu[]> {
    return this.menuRepository.find({ relations: { restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Menu> {
    const menu = await this.menuRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!menu) {
      throw new NotFoundException(`Menú con id ${id} no encontrado`);
    }
    return menu;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Menu[]> {
    return this.menuRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(id: number, dto: ActualizarMenuDto): Promise<Menu> {
    const menu = await this.buscarPorId(id);
    Object.assign(menu, dto);
    return this.menuRepository.save(menu);
  }

  async eliminar(id: number): Promise<void> {
    const menu = await this.buscarPorId(id);
    await this.menuRepository.delete(menu.id);
  }
}