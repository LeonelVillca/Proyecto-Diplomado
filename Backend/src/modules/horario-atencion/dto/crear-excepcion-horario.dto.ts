import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

const HORA_REGEX = /^([0-1]?\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

export class CrearExcepcionHorarioDto {
  @IsInt()
  idRestaurante: number;

  @IsDateString()
  fecha: string;

  @IsBoolean()
  cerrado: boolean;

  @IsOptional()
  @Matches(HORA_REGEX)
  horaInicio?: string;

  @IsOptional()
  @Matches(HORA_REGEX)
  horaFin?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  motivo?: string;
}
