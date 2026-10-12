import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { OauthCuentasService } from './oauth-cuentas.service';
import { CrearOauthCuentaDto } from './dto/crear-oauth-cuenta.dto';
import { ActualizarOauthCuentaDto } from './dto/actualizar-oauth-cuenta.dto';

@Controller('oauth-cuentas')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class OauthCuentasController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly oauthCuentasService: OauthCuentasService) {}

  // Lista las cuentas OAuth.
  @Get()
  listar() {
    return this.oauthCuentasService.listar();
  }

  // Crea una vinculación con un proveedor externo.
  @Post()
  crear(@Body() dto: CrearOauthCuentaDto) {
    return this.oauthCuentasService.crear(dto);
  }

  // Actualiza una cuenta OAuth.
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarOauthCuentaDto,
  ) {
    return this.oauthCuentasService.actualizar(id, dto);
  }
}
