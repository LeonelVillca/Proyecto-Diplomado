import { Type } from 'class-transformer';
import { IsISO8601, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CrearReporteDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idUsuario: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  tipo: string;

  @IsOptional()
  @IsISO8601()
  fechaInicio?: string;

  @IsOptional()
  @IsISO8601()
  fechaFin?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  estado?: string;
}