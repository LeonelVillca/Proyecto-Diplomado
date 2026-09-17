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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { RolPermisoService } from './rol-permiso.service';
import { CrearRolPermisoDto } from './dto/crear-rol-permiso.dto';
import { RolPermiso } from './rol-permiso.entity';

@Controller('rol-permiso')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class RolPermisoController {
  constructor(private readonly rolPermisoService: RolPermisoService) {}

  @Post()
  asignarPermiso(@Body() dto: CrearRolPermisoDto): Promise<RolPermiso> {
    return this.rolPermisoService.asignarPermiso(dto);
  }

  @Get()
  listarTodos(): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarTodos();
  }

  @Get('rol/:idRol')
  listarPermisosPorRol(
    @Param('idRol', ParseIntPipe) idRol: number,
  ): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarPermisosPorRol(idRol);
  }

  @Get('permiso/:idPermiso')
  listarRolesPorPermiso(
    @Param('idPermiso', ParseIntPipe) idPermiso: number,
  ): Promise<RolPermiso[]> {
    return this.rolPermisoService.listarRolesPorPermiso(idPermiso);
  }

  @Delete('rol/:idRol/permiso/:idPermiso')
  eliminarAsignacion(
    @Param('idRol', ParseIntPipe) idRol: number,
    @Param('idPermiso', ParseIntPipe) idPermiso: number,
  ): Promise<void> {
    return this.rolPermisoService.eliminarAsignacion(idRol, idPermiso);
  }
}
