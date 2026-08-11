import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OauthCuentasService } from './oauth-cuentas.service';
import { CrearOauthCuentaDto } from './dto/crear-oauth-cuenta.dto';
import { ActualizarOauthCuentaDto } from './dto/actualizar-oauth-cuenta.dto';

@Controller('oauth-cuentas')
export class OauthCuentasController {
  constructor(private readonly oauthCuentasService: OauthCuentasService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  listar() {
    return this.oauthCuentasService.listar();
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  crear(@Body() dto: CrearOauthCuentaDto) {
    return this.oauthCuentasService.crear(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarOauthCuentaDto,
  ) {
    return this.oauthCuentasService.actualizar(id, dto);
  }
}