import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Menu } from './menu.entity';
import { CrearMenuDto } from './dto/crear-menu.dto';
import { ActualizarMenuDto } from './dto/actualizar-menu.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Plato } from '../plato/plato.entity';

@Injectable()
export class MenuService {
  constructor(
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Plato)
    private readonly platoRepository: Repository<Plato>,
  ) {}

  async crear(dto: CrearMenuDto): Promise<Menu> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${dto.idRestaurante} no encontrado`);
    }

    const { idRestaurante, platos, ...datos } = dto;
    const menu = this.menuRepository.create({ ...datos, restaurante });
    const savedMenu = await this.menuRepository.save(menu);

    if (platos && platos.length > 0) {
      const platosEntities = platos.map(p => this.platoRepository.create({ ...p, menu: savedMenu }));
      await this.platoRepository.save(platosEntities);
    }

    return this.buscarPorId(savedMenu.id);
  }

  listarTodos(): Promise<Menu[]> {
    return this.menuRepository.find({ relations: { restaurante: true, platos: true } });
  }

  async buscarPorId(id: number): Promise<Menu> {
    const menu = await this.menuRepository.findOne({
      where: { id },
      relations: { restaurante: true, platos: true },
    });
    if (!menu) {
      throw new NotFoundException(`Menú con id ${id} no encontrado`);
    }
    return menu;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Menu[]> {
    return this.menuRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true, platos: true },
    });
  }

  async actualizar(id: number, dto: ActualizarMenuDto): Promise<Menu> {
    const menu = await this.buscarPorId(id);
    const { platos, ...datos } = dto as any;
    
    Object.assign(menu, datos);
    await this.menuRepository.save(menu);

    if (platos) {
      // Very basic sync: delete existing and insert new
      await this.platoRepository.delete({ menu: { id } });
      if (platos.length > 0) {
        const platosEntities = platos.map(p => this.platoRepository.create({ ...p, menu }));
        await this.platoRepository.save(platosEntities);
      }
    }

    return this.buscarPorId(id);
  }

  async eliminar(id: number): Promise<void> {
    const menu = await this.buscarPorId(id);
    await this.menuRepository.delete(menu.id);
  }
}
