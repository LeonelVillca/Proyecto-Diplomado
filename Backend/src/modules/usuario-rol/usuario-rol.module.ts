import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsuarioRol } from './usuario-rol.entity';
import { UsuarioRolService } from './usuario-rol.service';
import { UsuarioRolController } from './usuario-rol.controller';
import { Usuario } from '../usuarios/usuario.entity';
import { Rol } from '../rol/rol.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UsuarioRol, Usuario, Rol])],
  controllers: [UsuarioRolController],
  providers: [UsuarioRolService],
  exports: [UsuarioRolService],
})
export class UsuarioRolModule {}
