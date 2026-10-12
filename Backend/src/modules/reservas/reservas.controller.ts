import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Query,
  Delete,
  ParseIntPipe,
  UseGuards,
  Req,
  ForbiddenException,
} from '@nestjs/common';
import { ReservasService } from './reservas.service';
import { CrearReservaDto } from './dto/crear-reserva.dto';
import { ActualizarReservaDto } from './dto/actualizar-reserva.dto';
import { ConsultarDisponibilidadDto } from './dto/consultar-disponibilidad.dto';
import { ConsultarOcupacionDto } from './dto/consultar-ocupacion.dto';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { UsuarioRestauranteAccesoService } from '../usuario-restaurante/usuario-restaurante-acceso.service';

@Controller('reservas')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class ReservasController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    private readonly reservasService: ReservasService,
    private readonly accesoRestaurante: UsuarioRestauranteAccesoService,
  ) {}

  // Crea una reserva.
  @Post()
  crear(@Body() dto: CrearReservaDto, @Req() req: any) {
    if (dto.idUsuario !== req.user.id) {
      throw new ForbiddenException(
        'No puedes crear una reserva a nombre de otro usuario',
      );
    }
    return this.reservasService.crear(dto);
  }

  // Lista las reservas.
  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.reservasService.listarTodas();
  }

  // Consulta las mesas disponibles para un horario.
  @Get('disponibilidad')
  consultarDisponibilidad(@Query() dto: ConsultarDisponibilidadDto) {
    return this.reservasService.consultarDisponibilidad(dto);
  }

  // Consulta la ocupación de un restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Get('restaurante/:idRestaurante/ocupacion')
  consultarOcupacionRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
    @Query() dto: ConsultarOcupacionDto,
  ) {
    return this.reservasService.consultarOcupacionRestaurante(
      idRestaurante,
      dto.fecha,
      dto.hora,
      dto.duracionMinutos,
    );
  }

  // Lista las reservas de un usuario.
  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
    @Req() req: any,
  ) {
    if (req.user.id !== idUsuario) {
      throw new ForbiddenException('Solo puedes ver tus propias reservas');
    }
    return this.reservasService.listarPorUsuario(idUsuario);
  }

  // Lista las reservas de un restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ) {
    return this.reservasService.listarPorRestaurante(idRestaurante);
  }

  // Busca una reserva por su identificador.
  @Get(':id')
  async buscarPorId(@Param('id', ParseIntPipe) id: number, @Req() req: any) {
    const reserva = await this.reservasService.buscarPorId(id);

    if (reserva.usuario.id === req.user.id) return reserva;
    const acceso = await this.accesoRestaurante.obtenerAcceso(req.user.id);
    if (
      this.accesoRestaurante.puedeAdministrar(
        acceso,
        reserva.mesa.restaurante.id,
      )
    ) return reserva;
    throw new ForbiddenException('No tienes permisos para ver esta reserva');
  }

  // Actualiza una reserva.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarReservaDto,
  ) {
    return this.reservasService.actualizar(id, dto);
  }

  // Cancela una reserva solicitada por su usuario.
  @Patch(':id/cancelar')
  cancelarPorUsuario(
    @Param('id', ParseIntPipe) id: number,
    @Req() req: { user: { id: number } },
  ) {
    return this.reservasService.cancelarPorUsuario(id, req.user.id);
  }

  // Elimina una reserva.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number) {
    return this.reservasService.eliminar(id);
  }
}
