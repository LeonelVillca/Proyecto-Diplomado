import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearDocumentoAdjuntoDto } from './crear-documento-adjunto.dto';

export class ActualizarDocumentoAdjuntoDto extends OmitType(
  PartialType(CrearDocumentoAdjuntoDto),
  ['idSolicitud'],
) {}