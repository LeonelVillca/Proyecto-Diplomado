import { PartialType } from '@nestjs/mapped-types';
import { CrearPermisoDto } from './crear-permiso.dto';

export class ActualizarPermisoDto extends PartialType(CrearPermisoDto) {}
