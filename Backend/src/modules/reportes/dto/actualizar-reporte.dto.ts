import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearReporteDto } from './crear-reporte.dto';

export class ActualizarReporteDto extends OmitType(PartialType(CrearReporteDto), [
  'idUsuario',
]) {}