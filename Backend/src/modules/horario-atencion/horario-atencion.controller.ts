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
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { HorarioAtencionService } from './horario-atencion.service';
import { CrearHorarioAtencionDto } from './dto/crear-horario-atencion.dto';
import { ActualizarHorarioAtencionDto } from './dto/actualizar-horario-atencion.dto';
import { HorarioAtencion } from './horario-atencion.entity';
import { ExcepcionHorario } from './excepcion-horario.entity';
import { CrearExcepcionHorarioDto } from './dto/crear-excepcion-horario.dto';
import { ActualizarExcepcionHorarioDto } from './dto/actualizar-excepcion-horario.dto';

@Controller('horario-atencion')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class HorarioAtencionController {
  constructor(
    private readonly horarioAtencionService: HorarioAtencionService,
  ) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Post()
  crear(@Body() dto: CrearHorarioAtencionDto): Promise<HorarioAtencion> {
    return this.horarioAtencionService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<HorarioAtencion[]> {
    return this.horarioAtencionService.listarTodos();
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<HorarioAtencion[]> {
    return this.horarioAtencionService.listarPorRestaurante(idRestaurante);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Post('excepciones')
  crearExcepcion(
    @Body() dto: CrearExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    return this.horarioAtencionService.crearExcepcion(dto);
  }

  @Get('excepciones/restaurante/:idRestaurante')
  listarExcepciones(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<ExcepcionHorario[]> {
    return this.horarioAtencionService.listarExcepciones(idRestaurante);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Patch('excepciones/:id')
  actualizarExcepcion(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    return this.horarioAtencionService.actualizarExcepcion(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Delete('excepciones/:id')
  eliminarExcepcion(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.horarioAtencionService.eliminarExcepcion(id);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<HorarioAtencion> {
    return this.horarioAtencionService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarHorarioAtencionDto,
  ): Promise<HorarioAtencion> {
    return this.horarioAtencionService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.horarioAtencionService.eliminar(id);
  }
}
