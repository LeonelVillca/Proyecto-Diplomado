import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearSolicitudDto } from './crear-solicitud.dto';

export class ActualizarSolicitudDto extends OmitType(
  PartialType(CrearSolicitudDto),
  ['nombreUsuario', 'apellidoUsuario', 'correoUsuario'],
) {}