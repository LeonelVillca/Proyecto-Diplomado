import { Type } from 'class-transformer';
import {
  IsDateString,
  IsInt,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

export class ConsultarDisponibilidadDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @IsDateString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  fecha: string;

  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/)
  hora: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  numeroPersonas: number;

  @Type(() => Number)
  @IsInt()
  @Min(60)
  @Max(60)
  duracionMinutos: number;
}
