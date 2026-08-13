import { Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { Rol } from '../rol/rol.entity';
import { Permiso } from '../permiso/permiso.entity';

@Entity('rol_permiso')
export class RolPermiso {
  @PrimaryColumn({ name: 'id_rol' })
  idRol: number;

  @PrimaryColumn({ name: 'id_permiso' })
  idPermiso: number;

  @ManyToOne(() => Rol, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_rol' })
  rol: Rol;

  @ManyToOne(() => Permiso, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_permiso' })
  permiso: Permiso;
}