import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { UsuarioRolService } from './usuario-rol.service';
import { CrearUsuarioRolDto } from './dto/crear-usuario-rol.dto';
import { UsuarioRol } from './usuario-rol.entity';

@Controller('usuario-rol')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class UsuarioRolController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly usuarioRolService: UsuarioRolService) {}

  // Asigna un rol a un usuario.
  @Post()
  asignarRol(@Body() dto: CrearUsuarioRolDto): Promise<UsuarioRol> {
    return this.usuarioRolService.asignarRol(dto);
  }

  // Lista las asignaciones de roles a usuarios.
  @Get()
  listarTodos(): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarTodos();
  }

  // Lista los roles de un usuario.
  @Get('usuario/:idUsuario')
  listarRolesPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarRolesPorUsuario(idUsuario);
  }

  // Lista los usuarios que tienen un rol.
  @Get('rol/:idRol')
  listarUsuariosPorRol(
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarUsuariosPorRol(idRol);
  }

  // Elimina una asignación existente.
  @Delete('usuario/:idUsuario/rol/:idRol')
  eliminarAsignacion(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<void> {
    return this.usuarioRolService.eliminarAsignacion(idUsuario, idRol);
  }
}
