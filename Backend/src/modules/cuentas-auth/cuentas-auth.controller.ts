import { Body, Controller, Get, Param, ParseIntPipe, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { CuentasAuthService } from './cuentas-auth.service';
import { ActualizarCuentaAuthDto } from './dto/actualizar-cuenta-auth.dto';

@Controller('cuentas-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class CuentasAuthController {
  constructor(private readonly cuentasAuthService: CuentasAuthService) {}

  @Get()
  listar() {
    return this.cuentasAuthService.listar();
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarCuentaAuthDto,
  ) {
    return this.cuentasAuthService.actualizar(id, dto);
  }
}
