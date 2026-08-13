import { PartialType } from '@nestjs/mapped-types';
import { CrearImagenDto } from './crear-imagen.dto';

export class ActualizarImagenDto extends PartialType(CrearImagenDto) {}