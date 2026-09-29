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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { DataSource } from 'typeorm';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';

@Controller('reservas')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class ReservasController {
  constructor(
    private readonly reservasService: ReservasService,
    private readonly dataSource: DataSource,
  ) {}

  @Post()
  crear(@Body() dto: CrearReservaDto, @Req() req: any) {
    if (dto.idUsuario !== req.user.id) {
      throw new ForbiddenException(
        'No puedes crear una reserva a nombre de otro usuario',
      );
    }
    return this.reservasService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.reservasService.listarTodas();
  }

  @Get('disponibilidad')
  consultarDisponibilidad(@Query() dto: ConsultarDisponibilidadDto) {
    return this.reservasService.consultarDisponibilidad(dto);
  }

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

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ) {
    return this.reservasService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  async buscarPorId(@Param('id', ParseIntPipe) id: number, @Req() req: any) {
    const reserva = await this.reservasService.buscarPorId(id);

    if (reserva.usuario.id === req.user.id) return reserva;
    const roles = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: req.user.id },
      relations: { rol: true },
    });
    if (roles.some((r) => r.rol.nombre === 'admin_sistema')) return reserva;
    if (roles.some((r) => r.rol.nombre === 'admin_restaurante')) {
      const restaurante = await this.dataSource
        .getRepository(UsuarioRestaurante)
        .findOne({
          where: {
            idRestaurante: reserva.mesa.restaurante.id,
            idUsuario: req.user.id,
            activo: true,
          },
        });
      if (restaurante) return reserva;
    }
    throw new ForbiddenException('No tienes permisos para ver esta reserva');
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarReservaDto,
  ) {
    return this.reservasService.actualizar(id, dto);
  }

  @Patch(':id/cancelar')
  cancelarPorUsuario(
    @Param('id', ParseIntPipe) id: number,
    @Req() req: { user: { id: number } },
  ) {
    return this.reservasService.cancelarPorUsuario(id, req.user.id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number) {
    return this.reservasService.eliminar(id);
  }
}
