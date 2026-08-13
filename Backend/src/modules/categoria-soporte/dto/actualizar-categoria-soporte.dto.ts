import { PartialType } from '@nestjs/mapped-types';
import { CrearCategoriaSoporteDto } from './crear-categoria-soporte.dto';

export class ActualizarCategoriaSoporteDto extends PartialType(CrearCategoriaSoporteDto) {}