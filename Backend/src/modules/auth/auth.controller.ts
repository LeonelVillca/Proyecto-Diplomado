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
import { Usuario } from '../usuarios/usuario.entity';
import { AccesoService } from './services/acceso.service';
import { SesionesService } from './services/sesiones.service';
import { ContrasenasService } from './services/contrasenas.service';
import { RecuperacionService } from './services/recuperacion.service';
import { GoogleLoginDto } from './dto/google-login.dto';
import { LoginDto } from './dto/login.dto';
import { CrearContrasenaDto } from './dto/crear-contrasena.dto';
import {
  SolicitarRecuperacionDto,
  RestablecerPasswordDto,
  VerificarPinDto,
} from './dto/recuperar-password.dto';
import { JwtAuthGuard } from './security/jwt-auth.guard';

interface RequestConUsuario {
  user: Usuario & { sessionStartedAt: number; sessionVersion: number };
}

@Controller('auth')
export class AuthController {
  // Recibe los servicios de cada flujo de autenticacion.
  constructor(
    private readonly acceso: AccesoService,
    private readonly sesiones: SesionesService,
    private readonly contrasenas: ContrasenasService,
    private readonly recuperacion: RecuperacionService,
  ) {}

  @Post('google')
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  // Inicia sesion con Google.
  @HttpCode(HttpStatus.CREATED)
  loginGoogle(@Body() dto: GoogleLoginDto) {
    return this.acceso.loginGoogle(dto);
  }

  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('login')
  // Inicia sesion con correo y contrasena.
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.acceso.login(dto);
  }

  @Post('crear-contrasena')
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  // Crea una contrasena desde una invitacion.
  @HttpCode(HttpStatus.OK)
  crearContrasena(@Body() dto: CrearContrasenaDto) {
    return this.contrasenas.crearContrasena(dto);
  }

  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('solicitar-recuperacion')
  // Solicita un PIN de recuperacion.
  @HttpCode(HttpStatus.OK)
  solicitarRecuperacion(@Body() dto: SolicitarRecuperacionDto) {
    return this.recuperacion.solicitarRecuperacion(dto);
  }

  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('verificar-pin-recuperacion')
  // Verifica un PIN de recuperacion.
  @HttpCode(HttpStatus.OK)
  verificarPinRecuperacion(@Body() dto: VerificarPinDto) {
    return this.recuperacion.verificarPinRecuperacion(dto);
  }

  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('restablecer-password')
  // Restablece la contrasena.
  @HttpCode(HttpStatus.OK)
  restablecerPassword(@Body() dto: RestablecerPasswordDto) {
    return this.recuperacion.restablecerPassword(dto);
  }

  @UseGuards(JwtAuthGuard)
  // Devuelve el perfil del usuario autenticado.
  @Get('perfil')
  perfil(@Req() request: RequestConUsuario) {
    return this.sesiones.perfil(request.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @Post('renovar')
  // Renueva la sesion actual.
  @HttpCode(HttpStatus.OK)
  renovar(@Req() req: RequestConUsuario) {
    return this.sesiones.renovarSesion(req.user);
  }

  @UseGuards(JwtAuthGuard)
  @Post('cerrar-sesiones')
  // Cierra las sesiones del usuario.
  @HttpCode(HttpStatus.OK)
  cerrarSesiones(@Req() req: RequestConUsuario) {
    return this.sesiones.cerrarSesiones(req.user.id);
  }
}
