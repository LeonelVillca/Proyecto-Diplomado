import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Matches, Max, Min } from 'class-validator';

export const HORA_REGEX = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

export class CrearHorarioAtencionDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(6)
  diaSemana: number;

  @IsString()
  @IsNotEmpty()
  @Matches(HORA_REGEX, { message: 'horaInicio debe tener formato HH:MM[:SS]' })
  horaInicio: string;

  @IsString()
  @IsNotEmpty()
  @Matches(HORA_REGEX, { message: 'horaFin debe tener formato HH:MM[:SS]' })
  horaFin: string;
}