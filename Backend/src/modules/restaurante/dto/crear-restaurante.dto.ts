import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CrearRestauranteDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idSolicitud?: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  tipoComida?: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefono?: string;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  correo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  fotoPortada?: string;

  @IsOptional()
  @IsBoolean()
  estado?: boolean;
}