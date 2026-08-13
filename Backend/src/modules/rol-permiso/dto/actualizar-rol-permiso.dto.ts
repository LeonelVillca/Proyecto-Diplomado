import { PartialType } from '@nestjs/mapped-types';
import { CrearRolPermisoDto } from './crear-rol-permiso.dto';

export class ActualizarRolPermisoDto extends PartialType(CrearRolPermisoDto) {}