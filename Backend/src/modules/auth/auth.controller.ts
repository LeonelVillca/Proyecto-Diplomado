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
import { AuthService, UsuarioPublico } from './auth.service';
import { RegistroDto } from './dto/registro.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { LoginDto } from './dto/login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

interface RequestConUsuario {
  user: UsuarioPublico;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  registro(@Body() dto: RegistroDto) {
    return this.authService.registro(dto);
  }

  @Post('google')
  @HttpCode(HttpStatus.CREATED)
  loginGoogle(@Body() dto: GoogleLoginDto) {
    return this.authService.loginGoogle(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('perfil')
  perfil(@Req() request: any) {
    return this.authService.perfil(request.user.id);
  }
}
