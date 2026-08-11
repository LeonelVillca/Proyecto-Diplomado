import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class RegistroDto {
  @IsString()
  @MaxLength(100)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  apellido?: string;

  @IsEmail()
  @MaxLength(150)
  correo: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  ci?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}