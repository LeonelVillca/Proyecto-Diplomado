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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
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
  constructor(private readonly soporteService: SoporteService) {}

  @CheckClientOwnership('soporte')
  @Post()
  crear(@Body() dto: CrearSoporteDto): Promise<Soporte> {
    return this.soporteService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodos(): Promise<Soporte[]> {
    return this.soporteService.listarTodos();
  }

  @CheckClientOwnership('soporte')
  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorUsuario(idUsuario);
  }

  @Roles('admin_sistema')
  @Get('categoria/:idCategoria')
  listarPorCategoria(
    @Param('idCategoria', ParseIntPipe) idCategoria: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorCategoria(idCategoria);
  }

  @CheckClientOwnership('soporte')
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Soporte> {
    return this.soporteService.buscarPorId(id);
  }

  @Roles('admin_sistema')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarSoporteDto,
  ): Promise<Soporte> {
    return this.soporteService.actualizar(id, dto);
  }

  @Roles('admin_sistema')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.soporteService.eliminar(id);
  }
}