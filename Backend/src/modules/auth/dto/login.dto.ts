import { IsEmail, IsNotEmpty, IsString, MinLength, MaxLength } from 'class-validator';

export class LoginDto {
  @IsEmail()
  @IsNotEmpty()
  correo: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  @MaxLength(72, { message: 'La contraseña no puede superar 72 caracteres' })
  password: string;
}
