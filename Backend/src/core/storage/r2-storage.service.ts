import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class R2StorageService {
  private readonly logger = new Logger(R2StorageService.name);
  private readonly client?: S3Client;
  private readonly bucket?: string;
  private readonly configured: boolean;

  constructor(config: ConfigService) {
    const accountId = config.get<string>('R2_ACCOUNT_ID');
    const accessKeyId = config.get<string>('R2_ACCESS_KEY_ID');
    const secretAccessKey = config.get<string>('R2_SECRET_ACCESS_KEY');
    this.bucket = config.get<string>('R2_BUCKET_NAME');
    const endpoint = config.get<string>('R2_ENDPOINT') ?? (accountId ? `https://${accountId}.r2.cloudflarestorage.com` : undefined);
    this.configured = Boolean(endpoint && accessKeyId && secretAccessKey && this.bucket);
    this.logger.log(`R2 config: endpoint=${Boolean(endpoint)} accessKey=${Boolean(accessKeyId)} secretKey=${Boolean(secretAccessKey)} bucket=${Boolean(this.bucket)}`);

    if (this.configured) {
      this.client = new S3Client({
        region: 'auto',
        endpoint,
        credentials: { accessKeyId: accessKeyId!, secretAccessKey: secretAccessKey! },
      });
    }
  }

  private requireStorage(): { client: S3Client; bucket: string } {
    if (!this.configured || !this.client || !this.bucket) {
      throw new ServiceUnavailableException('El almacenamiento privado no está configurado');
    }
    return { client: this.client, bucket: this.bucket };
  }

  async upload(key: string, body: Buffer, contentType: string): Promise<void> {
    const { client, bucket } = this.requireStorage();
    await client.send(new PutObjectCommand({ Bucket: bucket, Key: key, Body: body, ContentType: contentType }));
  }

  async remove(key: string): Promise<void> {
    const { client, bucket } = this.requireStorage();
    await client.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
  }

  async signedDownloadUrl(key: string): Promise<string> {
    const { client, bucket } = this.requireStorage();
    return getSignedUrl(client, new GetObjectCommand({
      Bucket: bucket,
      Key: key,
      ResponseContentDisposition: 'attachment',
      ResponseCacheControl: 'private, no-store',
    }), { expiresIn: 300 });
  }
}
