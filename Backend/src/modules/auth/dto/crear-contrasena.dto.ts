import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CrearContrasenaDto {
  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password: string;
}
