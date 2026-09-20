import sharp from 'sharp';
import { sanitizeImage, validateDocument, MAX_IMAGE_BYTES } from './uploads';

describe('Archivos subidos', () => {
  const file = (buffer: Buffer, mimetype = 'image/jpeg') => ({ buffer, mimetype } as Express.Multer.File);
  it('recodifica una imagen válida, limita tamaño y descarta metadatos', async () => {
    const buffer = await sharp({ create: { width: 2000, height: 500, channels: 3, background: 'red' } }).png().toBuffer();
    const result = await sanitizeImage(file(buffer));
    const metadata = await sharp(result).metadata();
    expect(metadata.format).toBe('webp');
    expect(metadata.width).toBe(1600);
    expect(metadata.exif).toBeUndefined();
  });
  it('rechaza HTML disfrazado de JPEG', async () => { await expect(sanitizeImage(file(Buffer.from('<script>alert(1)</script>')))).rejects.toThrow(); });
  it('rechaza SVG aunque el MIME indique JPEG', async () => {
    await expect(sanitizeImage(file(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>')))).rejects.toThrow();
  });
  it('rechaza archivos mayores a 5 MB', async () => { await expect(sanitizeImage(file(Buffer.alloc(MAX_IMAGE_BYTES + 1)))).rejects.toThrow(); });
  it('rechaza PDF declarado sin firma PDF', async () => { await expect(validateDocument(file(Buffer.from('not pdf'), 'application/pdf'))).rejects.toThrow(); });
});
