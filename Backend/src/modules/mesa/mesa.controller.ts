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
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { MesaService } from './mesa.service';
import { CrearMesaDto } from './dto/crear-mesa.dto';
import { ActualizarMesaDto } from './dto/actualizar-mesa.dto';
import { ActualizarEstadoHorarioDto } from './dto/actualizar-estado-horario.dto';
import { Mesa } from './mesa.entity';

@Controller('mesa')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class MesaController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly mesaService: MesaService) {}

  // Crea una mesa.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Post()
  crear(@Body() dto: CrearMesaDto): Promise<Mesa> {
    return this.mesaService.crear(dto);
  }

  // Lista las mesas.
  @Get()
  listarTodos(): Promise<Mesa[]> {
    return this.mesaService.listarTodos();
  }

  // Lista las mesas de un restaurante.
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Mesa[]> {
    return this.mesaService.listarPorRestaurante(idRestaurante);
  }

  // Busca una mesa por su identificador.
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Mesa> {
    return this.mesaService.buscarPorId(id);
  }

  // Actualiza el estado de una mesa para un horario.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Patch(':id/estado-horario')
  actualizarEstadoHorario(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarEstadoHorarioDto,
  ) {
    return this.mesaService.actualizarEstadoHorario(id, dto);
  }

  // Actualiza una mesa.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarMesaDto,
  ): Promise<Mesa> {
    return this.mesaService.actualizar(id, dto);
  }

  // Elimina una mesa.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.mesaService.eliminar(id);
  }
}
