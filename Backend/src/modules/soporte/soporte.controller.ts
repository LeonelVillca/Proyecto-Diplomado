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
import { SoporteService } from './soporte.service';
import { CrearSoporteDto } from './dto/crear-soporte.dto';
import { ActualizarSoporteDto } from './dto/actualizar-soporte.dto';
import { Soporte } from './soporte.entity';

@Controller('soporte')
export class SoporteController {
  constructor(private readonly soporteService: SoporteService) {}

  @Post()
  crear(@Body() dto: CrearSoporteDto): Promise<Soporte> {
    return this.soporteService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Soporte[]> {
    return this.soporteService.listarTodos();
  }

  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorUsuario(idUsuario);
  }

  @Get('categoria/:idCategoria')
  listarPorCategoria(
    @Param('idCategoria', ParseIntPipe) idCategoria: number,
  ): Promise<Soporte[]> {
    return this.soporteService.listarPorCategoria(idCategoria);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Soporte> {
    return this.soporteService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarSoporteDto,
  ): Promise<Soporte> {
    return this.soporteService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.soporteService.eliminar(id);
  }
}