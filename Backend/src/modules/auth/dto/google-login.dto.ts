import { IsBoolean, IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class GoogleLoginDto {
  @IsEmail()
  @MaxLength(150)
  correo: string;

  @IsString()
  @MaxLength(100)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  apellido?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  foto?: string;

  @IsString()
  @MaxLength(255)
  proveedorId: string;

  @IsOptional()
  @IsBoolean()
  emailVerificado?: boolean;
}