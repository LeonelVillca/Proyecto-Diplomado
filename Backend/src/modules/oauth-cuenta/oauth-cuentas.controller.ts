import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { OauthCuentasService } from './oauth-cuentas.service';
import { CrearOauthCuentaDto } from './dto/crear-oauth-cuenta.dto';
import { ActualizarOauthCuentaDto } from './dto/actualizar-oauth-cuenta.dto';

@Controller('oauth-cuentas')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class OauthCuentasController {
  constructor(private readonly oauthCuentasService: OauthCuentasService) {}

  @Get()
  listar() {
    return this.oauthCuentasService.listar();
  }

  @Post()
  crear(@Body() dto: CrearOauthCuentaDto) {
    return this.oauthCuentasService.crear(dto);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarOauthCuentaDto,
  ) {
    return this.oauthCuentasService.actualizar(id, dto);
  }
}
