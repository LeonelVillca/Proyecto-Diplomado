import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CrearReservaDto } from './crear-reserva.dto';
import { IsIn, IsOptional, IsString } from 'class-validator';

export const ESTADO_RESERVA = ['pendiente', 'confirmada', 'rechazada', 'finalizada', 'cancelada'];

export class ActualizarReservaDto extends PartialType(
  OmitType(CrearReservaDto, ['idUsuario'] as const),
) {
  @IsOptional()
  @IsString()
  @IsIn(ESTADO_RESERVA)
  estado?: string;
}
