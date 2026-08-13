import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolPermiso } from './rol-permiso.entity';
import { RolPermisoService } from './rol-permiso.service';
import { RolPermisoController } from './rol-permiso.controller';
import { Rol } from '../rol/rol.entity';
import { Permiso } from '../permiso/permiso.entity';

@Module({
  imports: [TypeOrmModule.forFeature([RolPermiso, Rol, Permiso])],
  controllers: [RolPermisoController],
  providers: [RolPermisoService],
  exports: [RolPermisoService],
})
export class RolPermisoModule {}