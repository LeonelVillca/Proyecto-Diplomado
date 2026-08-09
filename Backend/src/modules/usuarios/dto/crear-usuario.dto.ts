import {
  IsEmail,
  IsIn,
  IsISO8601,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export const ESTADO_USUARIO = ['activo', 'suspendido', 'eliminado'] as const;

export class CrearUsuarioDto {
  @IsString()
  @IsNotEmpty()
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
  @IsISO8601()
  fechaNacimiento?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  foto?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefono?: string;

  @IsOptional()
  @IsIn(ESTADO_USUARIO)
  estado?: string;
}
