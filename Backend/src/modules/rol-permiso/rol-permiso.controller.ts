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
import { RolPermisoService } from './rol-permiso.service';
import { CrearRolPermisoDto } from './dto/crear-rol-permiso.dto';
import { RolPermiso } from './rol-permiso.entity';

@Controller('rol-permiso')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class RolPermisoController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly rolPermisoService: RolPermisoService) {}

  // Asigna un permiso a un rol.
  @Post()
  asignarPermiso(@Body() dto: CrearRolPermisoDto): Promise<RolPermiso> {
    return this.rolPermisoService.asignarPermiso(dto);
  }

  // Lista las asignaciones de permisos a roles.
  @Get()
  listarTodos(): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarTodos();
  }

  // Lista los permisos asignados a un rol.
  @Get('rol/:idRol')
  listarPermisosPorRol(
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarPermisosPorRol(idRol);
  }

  // Lista los roles que tienen un permiso.
  @Get('permiso/:idPermiso')
  listarRolesPorPermiso(
    @Param('idPermiso', ParseIntPipe) idPermiso: number,
  ): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarRolesPorPermiso(idPermiso);
  }

  // Elimina una asignación existente.
  @Delete('rol/:idRol/permiso/:idPermiso')
  eliminarAsignacion(
    @Param('idRol', ParseIntPipe) idRol: number,
    @Param('idPermiso', ParseIntPipe) idPermiso: number,
  ): Promise<void> {
    return this.rolPermisoService.eliminarAsignacion(idRol, idPermiso);
  }
}
