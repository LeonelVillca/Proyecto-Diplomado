import { PartialType } from '@nestjs/mapped-types';
import { CrearVisitaDto } from './crear-visita.dto';

export class ActualizarVisitaDto extends PartialType(CrearVisitaDto) {}