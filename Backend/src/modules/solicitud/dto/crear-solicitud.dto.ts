import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ESTADO_SOLICITUD } from '../solicitud.entity';

export class CrearSolicitudDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idUsuario: number;

  @IsString()
  @IsNotEmpty()
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