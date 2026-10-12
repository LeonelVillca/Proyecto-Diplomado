import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DocumentoAdjunto } from './documento-adjunto.entity';
import { CrearDocumentoAdjuntoDto } from './dto/crear-documento-adjunto.dto';
import { ActualizarDocumentoAdjuntoDto } from './dto/actualizar-documento-adjunto.dto';
import { Solicitud } from '../solicitud/solicitud.entity';

@Injectable()
export class DocumentoAdjuntoService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    @InjectRepository(DocumentoAdjunto)
    private readonly documentoRepository: Repository<DocumentoAdjunto>,
    @InjectRepository(Solicitud)
    private readonly solicitudRepository: Repository<Solicitud>,
  ) {}

  // Crea un documento adjunto.
  async crear(dto: CrearDocumentoAdjuntoDto): Promise<DocumentoAdjunto> {
    const solicitud = await this.solicitudRepository.findOneBy({
      id: dto.idSolicitud,
    });
    if (!solicitud) {
      throw new NotFoundException(
        `Solicitud con id ${dto.idSolicitud} no encontrada`,
      );
    }

    const documento = this.documentoRepository.create({
      tipo: dto.tipo,
      url: dto.url,
      solicitud,
    });
    return this.documentoRepository.save(documento);
  }

  // Lista los documentos adjuntos.
  listarTodos(): Promise<DocumentoAdjunto[]> {
    return this.documentoRepository.find({ relations: { solicitud: true } });
  }

  // Busca un documento adjunto por su identificador.
  async buscarPorId(id: number): Promise<DocumentoAdjunto> {
    const documento = await this.documentoRepository.findOne({
      where: { id },
      relations: { solicitud: true },
    });
    if (!documento) {
      throw new NotFoundException(
        `Documento adjunto con id ${id} no encontrado`,
      );
    }
    return documento;
  }

  // Lista los documentos de una solicitud.
  listarPorSolicitud(idSolicitud: number): Promise<DocumentoAdjunto[]> {
    return this.documentoRepository.find({
      where: { solicitud: { id: idSolicitud } },
      relations: { solicitud: true },
    });
  }

  // Actualiza un documento adjunto.
  async actualizar(
    id: number,
    dto: ActualizarDocumentoAdjuntoDto,
  ): Promise<DocumentoAdjunto> {
    const documento = await this.buscarPorId(id);
    Object.assign(documento, dto);
    return this.documentoRepository.save(documento);
  }

  // Elimina un documento adjunto.
  async eliminar(id: number): Promise<void> {
    const documento = await this.buscarPorId(id);
    await this.documentoRepository.delete(documento.id);
  }
}
