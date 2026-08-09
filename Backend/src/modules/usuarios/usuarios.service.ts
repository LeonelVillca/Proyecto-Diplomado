import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Usuario } from './usuario.entity';
import { CrearUsuarioDto } from './dto/crear-usuario.dto';
import { ActualizarUsuarioDto } from './dto/actualizar-usuario.dto';

@Injectable()
export class UsuariosService {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  crear(dto: CrearUsuarioDto): Promise<Usuario> {
    const usuario = this.usuarioRepository.create(dto);
    return this.usuarioRepository.save(usuario);
  }

  listarTodos(): Promise<Usuario[]> {
    return this.usuarioRepository.find();
  }

  async buscarPorId(id: number): Promise<Usuario> {
    const usuario = await this.usuarioRepository.findOneBy({ id });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${id} no encontrado`);
    }
    return usuario;
  }

  async buscarPorCorreo(correo: string): Promise<Usuario | null> {
    return this.usuarioRepository.findOneBy({ correo });
  }

  async actualizar(id: number, dto: ActualizarUsuarioDto): Promise<Usuario> {
    const usuario = await this.buscarPorId(id);
    Object.assign(usuario, dto);
    return this.usuarioRepository.save(usuario);
  }

  async eliminar(id: number): Promise<void> {
    const usuario = await this.buscarPorId(id);
    await this.usuarioRepository.delete(usuario.id);
  }
}
