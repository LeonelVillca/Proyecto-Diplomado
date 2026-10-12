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
import { ClientOwnershipGuard, CheckClientOwnership } from '../../core/guards/client-ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { SoporteService } from './soporte.service';
import { CrearSoporteDto } from './dto/crear-soporte.dto';
import { ActualizarSoporteDto } from './dto/actualizar-soporte.dto';
import { Soporte } from './soporte.entity';

@Controller('soporte')
@UseGuards(JwtAuthGuard, RolesGuard, ClientOwnershipGuard)
export class SoporteController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly soporteService: SoporteService) {}

  // Crea un ticket de soporte.
  @CheckClientOwnership('soporte')
  @Post()
  crear(@Body() dto: CrearSoporteDto): Promise<Soporte> {
    return this.soporteService.crear(dto);
  }

  // Lista los tickets de soporte.
  @Roles('admin_sistema')
  @Get()
  listarTodos(): Promise<Soporte[]> {
    return this.soporteService.listarTodos();
  }

  // Lista los tickets de soporte de un usuario.
  @CheckClientOwnership('soporte')
  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorUsuario(idUsuario);
  }

  // Lista los tickets de una categoría.
  @Roles('admin_sistema')
  @Get('categoria/:idCategoria')
  listarPorCategoria(
    @Param('idCategoria', ParseIntPipe) idCategoria: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorCategoria(idCategoria);
  }

  // Busca un ticket de soporte por su identificador.
  @CheckClientOwnership('soporte')
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Soporte> {
    return this.soporteService.buscarPorId(id);
  }

  // Actualiza un ticket de soporte.
  @Roles('admin_sistema')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarSoporteDto,
  ): Promise<Soporte> {
    return this.soporteService.actualizar(id, dto);
  }

  // Elimina un ticket de soporte.
  @Roles('admin_sistema')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.soporteService.eliminar(id);
  }
}