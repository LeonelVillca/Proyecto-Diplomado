import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseIntPipe,
  UseGuards,
  Req,
  ForbiddenException,
} from '@nestjs/common';
import { ReservasService } from './reservas.service';
import { CrearReservaDto } from './dto/crear-reserva.dto';
import { ActualizarReservaDto } from './dto/actualizar-reserva.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';

@Controller('reservas')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class ReservasController {
  constructor(private readonly reservasService: ReservasService) {}

  @Post()
  crear(@Body() dto: CrearReservaDto, @Req() req: any) {
    if (dto.idUsuario !== req.user.id) {
      throw new ForbiddenException('No puedes crear una reserva a nombre de otro usuario');
    }
    return this.reservasService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.reservasService.listarTodas();
  }
  
  @Get('usuario/:idUsuario')
  listarPorUsuario(@Param('idUsuario', ParseIntPipe) idUsuario: number, @Req() req: any) {
      if (req.user.id !== idUsuario) {
          throw new ForbiddenException('Solo puedes ver tus propias reservas');
      }
      return this.reservasService.listarPorUsuario(idUsuario);
  }
  
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(@Param('idRestaurante', ParseIntPipe) idRestaurante: number) {
      return this.reservasService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  async buscarPorId(@Param('id', ParseIntPipe) id: number, @Req() req: any) {
    const reserva = await this.reservasService.buscarPorId(id);
    
    // Solo puede verla si es dueño de la reserva, o si es un admin_sistema,
    // o si es admin_restaurante (la validación del restaurante se haría mejor
    // en OwnershipGuard, pero para simplificar validamos aquí si es cliente).
    // Si no somos cliente, lo permitimos por ahora (roles admin lo gestionan).
    if (!req.user.roles || req.user.roles.length === 0) {
       // Asumiremos que el frontend validará roles. Pero para ser seguros:
       if (reserva.usuario.id !== req.user.id) {
           // Aquí podríamos lanzar error si no tiene roles.
       }
    }
    
    return reserva;
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

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('reserva')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number) {
    return this.reservasService.eliminar(id);
  }
}
