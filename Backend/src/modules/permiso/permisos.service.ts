import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Permiso } from './permiso.entity';
import { CrearPermisoDto } from './dto/crear-permiso.dto';
import { ActualizarPermisoDto } from './dto/actualizar-permiso.dto';

@Injectable()
export class PermisosService {
  constructor(
    @InjectRepository(Permiso)
    private readonly permisoRepository: Repository<Permiso>,
  ) {}

  crear(dto: CrearPermisoDto): Promise<Permiso> {
    const permiso = this.permisoRepository.create(dto);
    return this.permisoRepository.save(permiso);
  }

  listarTodos(): Promise<Permiso[]> {
    return this.permisoRepository.find();
  }

  async buscarPorId(id: number): Promise<Permiso> {
    const permiso = await this.permisoRepository.findOneBy({ id });
    if (!permiso) {
      throw new NotFoundException(`Permiso con id ${id} no encontrado`);
    }
    return permiso;
  }

  async buscarPorCodigo(codigo: string): Promise<Permiso | null> {
    return this.permisoRepository.findOneBy({ codigo });
  }

  async actualizar(id: number, dto: ActualizarPermisoDto): Promise<Permiso> {
    const permiso = await this.buscarPorId(id);
    Object.assign(permiso, dto);
    return this.permisoRepository.save(permiso);
  }

  async eliminar(id: number): Promise<void> {
    const permiso = await this.buscarPorId(id);
    await this.permisoRepository.delete(permiso.id);
  }
}
