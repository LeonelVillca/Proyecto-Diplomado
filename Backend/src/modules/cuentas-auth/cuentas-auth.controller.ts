import { Body, Controller, Get, Param, ParseIntPipe, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CuentasAuthService } from './cuentas-auth.service';
import { ActualizarCuentaAuthDto } from './dto/actualizar-cuenta-auth.dto';

@Controller('cuentas-auth')
export class CuentasAuthController {
  constructor(private readonly cuentasAuthService: CuentasAuthService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  listar() {
    return this.cuentasAuthService.listar();
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarCuentaAuthDto,
  ) {
    return this.cuentasAuthService.actualizar(id, dto);
  }
}