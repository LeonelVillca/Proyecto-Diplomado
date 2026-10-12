import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { Plato } from './plato.entity';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { DatosPlatoDto } from './dto/datos-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Menu } from '../menu/menu.entity';

@Injectable()
export class PlatoService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    @InjectRepository(Plato)
    private readonly platoRepository: Repository<Plato>,
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
  ) {}

  // Crea un plato.
  async crear(dto: CrearPlatoDto): Promise<Plato> {
    const menu = await this.menuRepository.findOneBy({ id: dto.idMenu });
    if (!menu) {
      throw new NotFoundException(`Menú con id ${dto.idMenu} no encontrado`);
    }
    const [plato] = await this.crearEnMenu(this.platoRepository.manager, menu, [
      dto,
    ]);
    return plato;
  }

  // El menú llama estas operaciones con su EntityManager transaccional.
  crearEnMenu(
    manager: EntityManager,
    menu: Menu,
    datos: DatosPlatoDto[],
  ): Promise<Plato[]> {
    if (!datos.length) return Promise.resolve([]);
    const repository = manager.getRepository(Plato);
    return repository.save(
      datos.map((plato) =>
        repository.create({
          nombre: plato.nombre,
          precio: plato.precio,
          descripcion: plato.descripcion,
          fotoUrl: plato.fotoUrl,
          disponible: plato.disponible,
          menu,
        }),
      ),
    );
  }

  // Reemplaza los platos de un menú.
  async reemplazarEnMenu(
    manager: EntityManager,
    menu: Menu,
    datos: DatosPlatoDto[],
  ): Promise<void> {
    await manager.getRepository(Plato).delete({ menu: { id: menu.id } });
    await this.crearEnMenu(manager, menu, datos);
  }

  // Lista los platos.
  listarTodos(): Promise<Plato[]> {
    return this.platoRepository.find({ relations: { menu: true } });
  }

  // Busca un plato por su identificador.
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

  // Lista los platos de un menú.
  listarPorMenu(idMenu: number): Promise<Plato[]> {
    return this.platoRepository.find({
      where: { menu: { id: idMenu } },
      relations: { menu: true },
    });
  }

  // Actualiza un plato.
  async actualizar(id: number, dto: ActualizarPlatoDto): Promise<Plato> {
    const plato = await this.buscarPorId(id);
    Object.assign(plato, dto);
    return this.platoRepository.save(plato);
  }

  // Elimina un plato.
  async eliminar(id: number): Promise<void> {
    const plato = await this.buscarPorId(id);
    await this.platoRepository.delete(plato.id);
  }
}
