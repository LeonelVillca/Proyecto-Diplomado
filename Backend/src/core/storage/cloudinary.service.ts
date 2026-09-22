import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);
  private readonly configured: boolean;

  constructor(config: ConfigService) {
    const cloudName = config.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = config.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = config.get<string>('CLOUDINARY_API_SECRET');
    this.configured = Boolean(cloudName && apiKey && apiSecret);

    if (this.configured) {
      cloudinary.config({ cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret });
    }
  }

  async uploadWebp(buffer: Buffer, folder: string, publicId: string): Promise<UploadApiResponse> {
    if (!this.configured) {
      throw new ServiceUnavailableException('El almacenamiento de imágenes no está configurado');
    }

    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder, public_id: publicId, resource_type: 'image', format: 'webp', overwrite: false },
        (error, result) => {
          if (error || !result) {
            this.logger.error('Cloudinary upload failed', {
              message: error?.message,
              httpCode: error?.http_code,
            });
            reject(new ServiceUnavailableException('No se pudo guardar la imagen en Cloudinary'));
            return;
          }
          resolve(result);
        },
      );
      stream.end(buffer);
    });
  }
}
