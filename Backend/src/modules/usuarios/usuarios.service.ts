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

  async listarTodos(): Promise<any[]> {
    const usuarios = await this.usuarioRepository.query(`
      SELECT u.*, 
             CASE WHEN ca.id_cuenta IS NOT NULL THEN true ELSE false END as es_local,
             CASE WHEN oa.id_oauth IS NOT NULL THEN true ELSE false END as es_externo
      FROM usuarios u
      LEFT JOIN cuentas_auth ca ON u.id_usuario = ca.id_usuario
      LEFT JOIN oauth_cuenta oa ON u.id_usuario = oa.id_usuario
      ORDER BY u.id_usuario ASC
    `);
    return usuarios.map((u: any) => ({
      id: u.id_usuario,
      nombre: u.nombre,
      apellido: u.apellido,
      correo: u.correo,
      ci: u.ci,
      fechaNacimiento: u.fecha_nacimiento,
      foto: u.foto,
      telefono: u.telefono,
      estado: u.estado,
      fechaRegistro: u.fecha_registro,
      esLocal: u.es_local,
      esExterno: u.es_externo,
    }));
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
