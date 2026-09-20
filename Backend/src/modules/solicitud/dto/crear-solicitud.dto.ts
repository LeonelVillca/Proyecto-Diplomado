import { IsIn, IsOptional, IsString, MaxLength, IsEmail } from 'class-validator';
import { ESTADO_SOLICITUD } from '../solicitud.entity';

export class CrearSolicitudDto {
  @IsString()
  @MaxLength(100)
  nombreUsuario: string;

  @IsString()
  @MaxLength(100)
  apellidoUsuario: string;

  @IsString()
  @IsEmail()
  @MaxLength(150)
  correoUsuario: string;

  @IsString()
  @MaxLength(150)
  nombreRestaurante: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  tipoComida?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  nitNegocio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  celularContacto?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descripcion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  horariosAtencion?: string;

  @IsOptional()
  @IsIn(ESTADO_SOLICITUD)
  estado?: (typeof ESTADO_SOLICITUD)[number];

  @IsOptional()
  @IsString()
  @MaxLength(255)
  motivoRechazo?: string;
}