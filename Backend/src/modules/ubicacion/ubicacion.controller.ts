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
import { UbicacionService } from './ubicacion.service';
import { CrearUbicacionDto } from './dto/crear-ubicacion.dto';
import { ActualizarUbicacionDto } from './dto/actualizar-ubicacion.dto';
import { Ubicacion } from './ubicacion.entity';

@Controller('ubicacion')
export class UbicacionController {
  constructor(private readonly ubicacionService: UbicacionService) {}

  @Post()
  crear(@Body() dto: CrearUbicacionDto): Promise<Ubicacion> {
    return this.ubicacionService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Ubicacion[]> {
    return this.ubicacionService.listarTodos();
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Ubicacion[]> {
    return this.ubicacionService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Ubicacion> {
    return this.ubicacionService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarUbicacionDto,
  ): Promise<Ubicacion> {
    return this.ubicacionService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.ubicacionService.eliminar(id);
  }
}