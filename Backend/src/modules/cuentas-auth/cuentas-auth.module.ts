import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CuentaAuth } from './cuenta-auth.entity';
import { CuentasAuthService } from './cuentas-auth.service';
import { CuentasAuthController } from './cuentas-auth.controller';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Module({
  imports: [TypeOrmModule.forFeature([CuentaAuth])],
  controllers: [CuentasAuthController],
  providers: [CuentasAuthService, JwtAuthGuard],
  exports: [CuentasAuthService],
})
export class CuentasAuthModule {}