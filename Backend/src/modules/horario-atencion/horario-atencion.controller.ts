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
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    private readonly horarioAtencionService: HorarioAtencionService,
  ) {}

  // Crea un horario de atención.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Post()
  crear(@Body() dto: CrearHorarioAtencionDto): Promise<HorarioAtencion> {
    return this.horarioAtencionService.crear(dto);
  }

  // Lista los horarios de atención.
  @Get()
  listarTodos(): Promise<HorarioAtencion[]> {
    return this.horarioAtencionService.listarTodos();
  }

  // Lista los horarios de atención de un restaurante.
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<HorarioAtencion[]> {
    return this.horarioAtencionService.listarPorRestaurante(idRestaurante);
  }

  // Crea una excepción de horario.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Post('excepciones')
  crearExcepcion(
    @Body() dto: CrearExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    return this.horarioAtencionService.crearExcepcion(dto);
  }

  // Lista las excepciones de horario de un restaurante.
  @Get('excepciones/restaurante/:idRestaurante')
  listarExcepciones(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<ExcepcionHorario[]> {
    return this.horarioAtencionService.listarExcepciones(idRestaurante);
  }

  // Actualiza una excepción de horario.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Patch('excepciones/:id')
  actualizarExcepcion(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    return this.horarioAtencionService.actualizarExcepcion(id, dto);
  }

  // Elimina una excepción de horario.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('excepcion_horario')
  @Delete('excepciones/:id')
  eliminarExcepcion(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.horarioAtencionService.eliminarExcepcion(id);
  }

  // Busca un horario de atención por su identificador.
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<HorarioAtencion> {
    return this.horarioAtencionService.buscarPorId(id);
  }

  // Actualiza un horario de atención.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarHorarioAtencionDto,
  ): Promise<HorarioAtencion> {
    return this.horarioAtencionService.actualizar(id, dto);
  }

  // Elimina un horario de atención.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('horario_atencion')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.horarioAtencionService.eliminar(id);
  }
}
