import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { UsuarioRolService } from './usuario-rol.service';
import { CrearUsuarioRolDto } from './dto/crear-usuario-rol.dto';
import { UsuarioRol } from './usuario-rol.entity';

@Controller('usuario-rol')
export class UsuarioRolController {
  constructor(private readonly usuarioRolService: UsuarioRolService) {}

  @Post()
  asignarRol(@Body() dto: CrearUsuarioRolDto): Promise<UsuarioRol> {
    return this.usuarioRolService.asignarRol(dto);
  }

  @Get()
  listarTodos(): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarTodos();
  }

  @Get('usuario/:idUsuario')
  listarRolesPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarRolesPorUsuario(idUsuario);
  }

  @Get('rol/:idRol')
  listarUsuariosPorRol(
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<UsuarioRol[]> {
    return this.usuarioRolService.listarUsuariosPorRol(idRol);
  }

  @Delete('usuario/:idUsuario/rol/:idRol')
  eliminarAsignacion(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<void> {
    return this.usuarioRolService.eliminarAsignacion(idUsuario, idRol);
  }
}
