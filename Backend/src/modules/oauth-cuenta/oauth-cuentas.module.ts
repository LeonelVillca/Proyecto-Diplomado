import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OauthCuenta } from './oauth-cuenta.entity';
import { OauthCuentasService } from './oauth-cuentas.service';
import { OauthCuentasController } from './oauth-cuentas.controller';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Module({
  imports: [TypeOrmModule.forFeature([OauthCuenta])],
  controllers: [OauthCuentasController],
  providers: [OauthCuentasService, JwtAuthGuard],
  exports: [OauthCuentasService],
})
export class OauthCuentasModule {}