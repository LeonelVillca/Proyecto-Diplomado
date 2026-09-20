import { BadRequestException } from '@nestjs/common';
import type { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';
import sharp from 'sharp';

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const imageUploadOptions: MulterOptions = {
  limits: { fileSize: MAX_IMAGE_BYTES, files: 10, fields: 12, fieldSize: 16 * 1024, parts: 22 },
  fileFilter: (_req, file, cb) => {
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
      return cb(new BadRequestException('Solo se permiten imágenes JPG, PNG o WEBP'), false);
    }
    cb(null, true);
  },
};

export async function sanitizeImage(file: Express.Multer.File): Promise<Buffer> {
  if (!file?.buffer?.length || file.buffer.length > MAX_IMAGE_BYTES) {
    throw new BadRequestException('La imagen es obligatoria y no debe superar 5 MB');
  }
  try {
    const image = sharp(file.buffer, { limitInputPixels: 20_000_000, failOn: 'warning' });
    const meta = await image.metadata();
    if (!['jpeg', 'png', 'webp'].includes(meta.format ?? '') || !meta.width || !meta.height
      || meta.width > 8192 || meta.height > 8192 || (meta.pages ?? 1) > 1) throw new Error('invalid image');
    return await image.rotate().resize(1600, 1600, { fit: 'inside', withoutEnlargement: true }).webp({ quality: 82 }).toBuffer();
  } catch {
    throw new BadRequestException('Imagen inválida, animada o con dimensiones demasiado grandes');
  }
}

export async function validateDocument(file: Express.Multer.File): Promise<void> {
  if (!file?.buffer?.length || file.buffer.length > MAX_IMAGE_BYTES) throw new BadRequestException('Documento inválido o mayor a 5 MB');
  if (file.mimetype === 'application/pdf') {
    if (!file.buffer.subarray(0, 8).toString('ascii').startsWith('%PDF-')
      || !file.buffer.subarray(-1024).includes(Buffer.from('%%EOF'))) throw new BadRequestException('El documento no es un PDF válido');
  } else {
    // Verificar contenido real y recodificar para eliminar metadatos/contenido añadido.
    const normalized = await sanitizeImage(file);
    file.buffer = await sharp(normalized).toFormat(file.mimetype === 'image/jpeg' ? 'jpeg' : 'png').toBuffer();
  }
}
