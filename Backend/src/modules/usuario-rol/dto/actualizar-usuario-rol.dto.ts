import { PartialType } from '@nestjs/mapped-types';
import { CrearUsuarioRolDto } from './crear-usuario-rol.dto';

export class ActualizarUsuarioRolDto extends PartialType(CrearUsuarioRolDto) {}
