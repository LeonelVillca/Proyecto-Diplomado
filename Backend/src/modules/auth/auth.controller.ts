import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService, UsuarioPublico } from './auth.service';
import { GoogleLoginDto } from './dto/google-login.dto';
import { LoginDto } from './dto/login.dto';
import { CrearContrasenaDto } from './dto/crear-contrasena.dto';
import { SolicitarRecuperacionDto, RestablecerPasswordDto, VerificarPinDto } from './dto/recuperar-password.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

interface RequestConUsuario {
  user: UsuarioPublico;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('google')
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @HttpCode(HttpStatus.CREATED)
  loginGoogle(@Body() dto: GoogleLoginDto) {
    return this.authService.loginGoogle(dto);
  }

  // VUL-003 / BB-02: Rate limiting estricto en login — 10 intentos por minuto
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('crear-contrasena')
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @HttpCode(HttpStatus.OK)
  crearContrasena(@Body() dto: CrearContrasenaDto) {
    return this.authService.crearContrasena(dto);
  }

  // BB-01 / BB-02: Rate limiting en recuperación — 5 solicitudes por minuto
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('solicitar-recuperacion')
  @HttpCode(HttpStatus.OK)
  solicitarRecuperacion(@Body() dto: SolicitarRecuperacionDto) {
    return this.authService.solicitarRecuperacion(dto);
  }

  // BB-02: Rate limiting estricto en verificación de PIN — 10 intentos por minuto
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('verificar-pin-recuperacion')
  @HttpCode(HttpStatus.OK)
  verificarPinRecuperacion(@Body() dto: VerificarPinDto) {
    return this.authService.verificarPinRecuperacion(dto);
  }

  // BB-02: Rate limiting estricto en restablecimiento — 5 por minuto
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('restablecer-password')
  @HttpCode(HttpStatus.OK)
  restablecerPassword(@Body() dto: RestablecerPasswordDto) {
    return this.authService.restablecerPassword(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('perfil')
  perfil(@Req() request: RequestConUsuario) {
    return this.authService.perfil((request.user as any).id);
  }

  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('renovar')
  @HttpCode(HttpStatus.OK)
  renovar(@Req() req: any) {
    return this.authService.renovarSesion(req.user);
  }

  @UseGuards(JwtAuthGuard)
  @Post('cerrar-sesiones')
  @HttpCode(HttpStatus.OK)
  cerrarSesiones(@Req() req: any) {
    return this.authService.cerrarSesiones(req.user.id);
  }
}
