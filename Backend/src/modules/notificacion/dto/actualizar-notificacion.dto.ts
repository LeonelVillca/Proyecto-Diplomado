import { OmitType, PartialType } from '@nestjs/mapped-types';
import { IsBoolean, IsOptional } from 'class-validator';
import { CrearNotificacionDto } from './crear-notificacion.dto';

export class ActualizarNotificacionDto extends OmitType(
  PartialType(CrearNotificacionDto),
  ['idUsuario'],
) {
  @IsOptional()
  @IsBoolean()
  leido?: boolean;
}