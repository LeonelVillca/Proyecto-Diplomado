import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { ESTADO_SOPORTE } from '../soporte.entity';

export class CrearSoporteDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idUsuario: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  idCategoriaSoporte: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  asunto: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsIn(ESTADO_SOPORTE)
  estado?: (typeof ESTADO_SOPORTE)[number];
}