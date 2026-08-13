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
import { SolicitudService } from './solicitud.service';
import { CrearSolicitudDto } from './dto/crear-solicitud.dto';
import { ActualizarSolicitudDto } from './dto/actualizar-solicitud.dto';
import { Solicitud } from './solicitud.entity';

@Controller('solicitud')
export class SolicitudController {
  constructor(private readonly solicitudService: SolicitudService) {}

  @Post()
  crear(@Body() dto: CrearSolicitudDto): Promise<Solicitud> {
    return this.solicitudService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Solicitud[]> {
    return this.solicitudService.listarTodos();
  }

  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Solicitud[]> {
    return this.solicitudService.listarPorUsuario(idUsuario);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Solicitud> {
    return this.solicitudService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarSolicitudDto,
  ): Promise<Solicitud> {
    return this.solicitudService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.solicitudService.eliminar(id);
  }
}