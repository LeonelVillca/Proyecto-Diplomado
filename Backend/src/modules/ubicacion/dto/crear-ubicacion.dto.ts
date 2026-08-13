import { Type } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CrearUbicacionDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  direccion?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitud?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitud?: number;
}