import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
  IsArray,
} from 'class-validator';

export class PlatoDetalleDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  nombre: string;

  @Type(() => Number)
  @Min(0)
  precio: number;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsString()
  fotoUrl?: string;

  @IsOptional()
  @IsBoolean()
  disponible?: boolean;
}

export class CrearMenuDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  descripcion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  tipo?: string;

  @IsOptional()
  @IsBoolean()
  disponibilidad?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlatoDetalleDto)
  platos?: PlatoDetalleDto[];
}
