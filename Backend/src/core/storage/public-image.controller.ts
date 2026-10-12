import { Controller, Get, Param, ParseIntPipe, Res } from '@nestjs/common';
import type { Response } from 'express';
import {
  PublicImageKind,
  PublicImageStorageService,
} from './public-image-storage.service';

@Controller('publico/restaurantes')
export class PublicImageController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly images: PublicImageStorageService) {}

  // Lee un archivo del almacenamiento configurado.
  @Get(':id/:kind/:filename')
  async read(
    @Param('id', ParseIntPipe) id: number,
    @Param('kind') kind: string,
    @Param('filename') filename: string,
    @Res() response: Response,
  ): Promise<void> {
    if (!['portada', 'logo', 'galeria', 'platos'].includes(kind)) {
      response.status(404).end();
      return;
    }
    const content = await this.images.read(
      id,
      kind as PublicImageKind,
      filename,
    );
    response.setHeader('Content-Type', 'image/webp');
    response.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    if (Buffer.isBuffer(content)) {
      response.end(content);
    } else {
      content.pipe(response);
    }
  }
}
