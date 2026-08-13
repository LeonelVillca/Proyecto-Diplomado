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

export class CrearNotificacionDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idUsuario: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  tipo: string;

  @IsString()
  @IsNotEmpty()
  mensaje: string;

  @IsOptional()
  @IsBoolean()
  leido?: boolean;
}