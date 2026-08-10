import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { PermisosService } from './permisos.service';
import { CrearPermisoDto } from './dto/crear-permiso.dto';
import { ActualizarPermisoDto } from './dto/actualizar-permiso.dto';
import { Permiso } from './permiso.entity';

@Controller('permisos')
export class PermisosController {
  constructor(private readonly permisosService: PermisosService) {}

  @Post()
  crear(@Body() dto: CrearPermisoDto): Promise<Permiso> {
    return this.permisosService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Permiso[]> {
    return this.permisosService.listarTodos();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Permiso> {
    return this.permisosService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarPermisoDto,
  ): Promise<Permiso> {
    return this.permisosService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.permisosService.eliminar(id);
  }
}
