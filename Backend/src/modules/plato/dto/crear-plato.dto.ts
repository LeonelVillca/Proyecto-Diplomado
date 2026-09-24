import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CrearPlatoDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idMenu: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  nombre: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  precio: number;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsString()
  fotoUrl?: string | null;

  @IsOptional()
  @IsBoolean()
  disponible?: boolean;
}