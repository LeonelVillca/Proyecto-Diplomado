import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearMenuDto } from './crear-menu.dto';

export class ActualizarMenuDto extends OmitType(PartialType(CrearMenuDto), [
  'idRestaurante',
]) {}