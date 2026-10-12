import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { PermisosService } from './permisos.service';
import { CrearPermisoDto } from './dto/crear-permiso.dto';
import { ActualizarPermisoDto } from './dto/actualizar-permiso.dto';
import { Permiso } from './permiso.entity';

@Controller('permisos')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class PermisosController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly permisosService: PermisosService) {}

  // Crea un permiso.
  @Post()
  crear(@Body() dto: CrearPermisoDto): Promise<Permiso> {
    return this.permisosService.crear(dto);
  }

  // Lista los permisos.
  @Get()
  listarTodos(): Promise<Permiso[]> {
    return this.permisosService.listarTodos();
  }

  // Busca un permiso por su identificador.
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Permiso> {
    return this.permisosService.buscarPorId(id);
  }

  // Actualiza un permiso.
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarPermisoDto,
  ): Promise<Permiso> {
    return this.permisosService.actualizar(id, dto);
  }

  // Elimina un permiso.
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.permisosService.eliminar(id);
  }
}
