import { PartialType } from '@nestjs/mapped-types';
import { CrearRolDto } from './crear-rol.dto';

export class ActualizarRolDto extends PartialType(CrearRolDto) {}
