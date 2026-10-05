import { Module } from '@nestjs/common';
import { R2StorageService } from './r2-storage.service';
import { PublicImageStorageService } from './public-image-storage.service';
import { PublicImageController } from './public-image.controller';

@Module({
  controllers: [PublicImageController],
  providers: [R2StorageService, PublicImageStorageService],
  exports: [R2StorageService, PublicImageStorageService],
})
export class StorageModule {}
