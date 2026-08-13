import { OmitType, PartialType } from '@nestjs/mapped-types';
import { IsIn, IsOptional, IsString } from 'class-validator';
import { CrearSoporteDto } from './crear-soporte.dto';
import { ESTADO_SOPORTE } from '../soporte.entity';

export class ActualizarSoporteDto extends OmitType(PartialType(CrearSoporteDto), [
  'idUsuario',
  'idCategoriaSoporte',
]) {
  @IsOptional()
  @IsString()
  respuesta?: string;

  @IsOptional()
  @IsIn(ESTADO_SOPORTE)
  estado?: (typeof ESTADO_SOPORTE)[number];
}