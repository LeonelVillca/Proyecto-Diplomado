import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { CuentasAuthService } from './cuentas-auth.service';
import { ActualizarCuentaAuthDto } from './dto/actualizar-cuenta-auth.dto';
import { CuentaAuth } from './cuenta-auth.entity';

@Controller('cuentas-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class CuentasAuthController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly cuentasAuthService: CuentasAuthService) {}

  // Lista las cuentas de acceso.
  @Get()
  async listar() {
    return (await this.cuentasAuthService.listar()).map((cuenta) =>
      this.aPublico(cuenta),
    );
  }

  // Actualiza una cuenta de acceso.
  @Patch(':id')
  async actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarCuentaAuthDto,
  ) {
    return this.aPublico(await this.cuentasAuthService.actualizar(id, dto));
  }

  // Convierte la cuenta a su versión pública.
  private aPublico(cuenta: CuentaAuth) {
    return {
      id: cuenta.id,
      usuario: cuenta.usuario,
      ultimoIngreso: cuenta.ultimoIngreso,
      intentosFallidos: cuenta.intentosFallidos,
      estado: cuenta.estado,
    };
  }
}
