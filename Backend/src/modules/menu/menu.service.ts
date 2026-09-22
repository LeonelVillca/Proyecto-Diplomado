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
  ) {}

  async crear(dto: CrearMenuDto): Promise<Menu> {
    const id = await this.menuRepository.manager.transaction(
      async (manager) => {
        const restaurante = await manager.findOneBy(Restaurante, {
          id: dto.idRestaurante,
        });
        if (!restaurante) {
          throw new NotFoundException(
            `Restaurante con id ${dto.idRestaurante} no encontrado`,
          );
        }

        const platos = dto.platos;
        const datos = {
          nombre: dto.nombre,
          descripcion: dto.descripcion,
          tipo: dto.tipo,
          disponibilidad: dto.disponibilidad,
        };
        const savedMenu = await manager.save(
          manager.create(Menu, { ...datos, restaurante }),
        );
        if (platos?.length) {
          await manager.save(
            Plato,
            platos.map((plato) =>
              manager.create(Plato, { ...plato, menu: savedMenu }),
            ),
          );
        }
        return savedMenu.id;
      },
    );
    return this.buscarPorId(id);
  }

  listarTodos(): Promise<Menu[]> {
    return this.menuRepository.find({
      relations: { restaurante: true, platos: true },
    });
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
    await this.menuRepository.manager.transaction(async (manager) => {
      const menu = await manager.findOne(Menu, { where: { id } });
      if (!menu) throw new NotFoundException(`Menú con id ${id} no encontrado`);

      const { platos, ...datos } = dto;
      Object.assign(menu, datos);
      await manager.save(menu);

      if (platos !== undefined) {
        await manager.delete(Plato, { menu: { id } });
        if (platos.length) {
          await manager.save(
            Plato,
            platos.map((plato) => manager.create(Plato, { ...plato, menu })),
          );
        }
      }
    });
    return this.buscarPorId(id);
  }

  async eliminar(id: number): Promise<void> {
    const menu = await this.buscarPorId(id);
    await this.menuRepository.delete(menu.id);
  }
}
