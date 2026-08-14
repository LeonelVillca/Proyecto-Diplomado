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
import { Roles } from '../../core/decorators/roles.decorator';
import { ReportesService } from './reportes.service';
import { CrearReporteDto } from './dto/crear-reporte.dto';
import { ActualizarReporteDto } from './dto/actualizar-reporte.dto';
import { Reporte } from './reporte.entity';

@Controller('reportes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class ReportesController {
  constructor(private readonly reportesService: ReportesService) {}

  @Post()
  crear(@Body() dto: CrearReporteDto): Promise<Reporte> {
    return this.reportesService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Reporte[]> {
    return this.reportesService.listarTodos();
  }

  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Reporte[]> {
    return this.reportesService.listarPorUsuario(idUsuario);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Reporte> {
    return this.reportesService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarReporteDto,
  ): Promise<Reporte> {
    return this.reportesService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.reportesService.eliminar(id);
  }
}