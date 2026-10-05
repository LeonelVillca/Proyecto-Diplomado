import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { R2StorageService } from './r2-storage.service';

export type PublicImageKind = 'portada' | 'logo' | 'galeria' | 'platos';

@Injectable()
export class PublicImageStorageService {
  private readonly production: boolean;

  constructor(
    config: ConfigService,
    private readonly r2: R2StorageService,
  ) {
    this.production = config.get<string>('NODE_ENV') === 'production';
  }

  async uploadWebp(
    buffer: Buffer,
    idRestaurante: number,
    kind: PublicImageKind,
  ): Promise<string> {
    const filename = `${randomUUID()}.webp`;
    const key = `restaurantes/${idRestaurante}/${kind}/${filename}`;
    if (this.production) {
      await this.r2.upload(key, buffer, 'image/webp');
    } else {
      const file = join(process.cwd(), 'storage', 'publico', key);
      await mkdir(
        join(
          process.cwd(),
          'storage',
          'publico',
          'restaurantes',
          String(idRestaurante),
          kind,
        ),
        { recursive: true },
      );
      await writeFile(file, buffer);
    }
    return `/api/v1/publico/${key}`;
  }

  async read(
    idRestaurante: number,
    kind: PublicImageKind,
    filename: string,
  ): Promise<Buffer | NodeJS.ReadableStream> {
    if (
      !Number.isSafeInteger(idRestaurante) ||
      idRestaurante < 1 ||
      !/^[0-9a-f-]{36}\.webp$/i.test(filename)
    ) {
      throw new NotFoundException('Imagen no encontrada');
    }
    const key = `restaurantes/${idRestaurante}/${kind}/${filename}`;
    try {
      if (this.production) return (await this.r2.download(key)).body;
      return await readFile(join(process.cwd(), 'storage', 'publico', key));
    } catch {
      throw new NotFoundException('Imagen no encontrada');
    }
  }

  async removeGalleryUrl(url: string): Promise<void> {
    const match =
      /^\/api\/v1\/publico\/restaurantes\/(\d+)\/galeria\/([0-9a-f-]{36}\.webp)$/i.exec(
        url,
      );
    if (!match) return;
    const key = `restaurantes/${match[1]}/galeria/${match[2]}`;
    if (this.production) {
      await this.r2.remove(key);
    } else {
      await unlink(join(process.cwd(), 'storage', 'publico', key));
    }
  }
}
