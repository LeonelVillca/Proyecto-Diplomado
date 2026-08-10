import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rol } from './rol.entity';
import { CrearRolDto } from './dto/crear-rol.dto';
import { ActualizarRolDto } from './dto/actualizar-rol.dto';

@Injectable()
export class RolesService {
  constructor(
    @InjectRepository(Rol)
    private readonly rolRepository: Repository<Rol>,
  ) {}

  crear(dto: CrearRolDto): Promise<Rol> {
    const rol = this.rolRepository.create(dto);
    return this.rolRepository.save(rol);
  }

  listarTodos(): Promise<Rol[]> {
    return this.rolRepository.find();
  }

  async buscarPorId(id: number): Promise<Rol> {
    const rol = await this.rolRepository.findOneBy({ id });
    if (!rol) {
      throw new NotFoundException(`Rol con id ${id} no encontrado`);
    }
    return rol;
  }

  async buscarPorNombre(nombre: string): Promise<Rol | null> {
    return this.rolRepository.findOneBy({ nombre });
  }

  async actualizar(id: number, dto: ActualizarRolDto): Promise<Rol> {
    const rol = await this.buscarPorId(id);
    Object.assign(rol, dto);
    return this.rolRepository.save(rol);
  }

  async eliminar(id: number): Promise<void> {
    const rol = await this.buscarPorId(id);
    await this.rolRepository.delete(rol.id);
  }
}
