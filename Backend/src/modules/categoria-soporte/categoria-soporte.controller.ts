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
import { CategoriaSoporteService } from './categoria-soporte.service';
import { CrearCategoriaSoporteDto } from './dto/crear-categoria-soporte.dto';
import { ActualizarCategoriaSoporteDto } from './dto/actualizar-categoria-soporte.dto';
import { CategoriaSoporte } from './categoria-soporte.entity';

@Controller('categoria-soporte')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class CategoriaSoporteController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly categoriaSoporteService: CategoriaSoporteService) {}

  // Crea una categoría de soporte.
  @Post()
  crear(@Body() dto: CrearCategoriaSoporteDto): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.crear(dto);
  }

  // Lista las categorías de soporte.
  @Roles()
  @Get()
  listarTodas(): Promise<CategoriaSoporte[]> {
    return this.categoriaSoporteService.listarTodas();
  }

  // Busca una categoría de soporte por su identificador.
  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.buscarPorId(id);
  }

  // Actualiza una categoría de soporte.
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarCategoriaSoporteDto,
  ): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.actualizar(id, dto);
  }

  // Elimina una categoría de soporte.
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.categoriaSoporteService.eliminar(id);
  }
}