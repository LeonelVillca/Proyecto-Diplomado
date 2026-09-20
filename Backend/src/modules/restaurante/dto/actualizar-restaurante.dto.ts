import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearRestauranteDto } from './crear-restaurante.dto';

export class ActualizarRestauranteDto extends PartialType(OmitType(CrearRestauranteDto, ['idSolicitud'] as const)) {}
