import { ConfigService } from '@nestjs/config';
import { PublicImageStorageService } from './public-image-storage.service';
import { R2StorageService } from './r2-storage.service';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';

jest.mock('node:fs/promises', () => ({
  mkdir: jest.fn(),
  readFile: jest.fn(),
  unlink: jest.fn(),
  writeFile: jest.fn(),
}));

describe('Almacenamiento de imágenes públicas', () => {
  const bytes = Buffer.from('webp');
  const r2 = {
    upload: jest.fn(),
    download: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(() => jest.clearAllMocks());

  it('guarda localmente en desarrollo y conserva una URL pública para Flutter', async () => {
    const images = new PublicImageStorageService(
      { get: () => 'development' } as unknown as ConfigService,
      r2 as unknown as R2StorageService,
    );
    const url = await images.uploadWebp(bytes, 7, 'platos');
    expect(url).toMatch(
      /^\/api\/v1\/publico\/restaurantes\/7\/platos\/[0-9a-f-]{36}\.webp$/,
    );
    expect(mkdir).toHaveBeenCalledTimes(1);
    expect(writeFile).toHaveBeenCalledWith(
      expect.stringContaining('storage'),
      bytes,
    );
    expect(r2.upload).not.toHaveBeenCalled();
  });

  it('usa R2 en producción y permite leer y borrar la misma clave', async () => {
    const images = new PublicImageStorageService(
      { get: () => 'production' } as unknown as ConfigService,
      r2 as unknown as R2StorageService,
    );
    const url = await images.uploadWebp(bytes, 7, 'galeria');
    const key = url.replace('/api/v1/publico/', '');
    expect(r2.upload).toHaveBeenCalledWith(key, bytes, 'image/webp');
    expect(writeFile).not.toHaveBeenCalled();
    r2.download.mockResolvedValue({ body: bytes });
    expect(await images.read(7, 'galeria', key.split('/').pop()!)).toBe(bytes);
    await images.removeGalleryUrl(url);
    expect(r2.remove).toHaveBeenCalledWith(key);
    expect(readFile).not.toHaveBeenCalled();
    expect(unlink).not.toHaveBeenCalled();
  });
});
