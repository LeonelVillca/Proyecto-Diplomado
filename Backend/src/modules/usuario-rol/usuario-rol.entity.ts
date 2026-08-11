import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Rol } from '../rol/rol.entity';

@Entity('usuario_rol')
export class UsuarioRol {
  @PrimaryColumn({ name: 'id_usuario' })
  idUsuario: number;

  @PrimaryColumn({ name: 'id_rol' })
  idRol: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Rol, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'id_rol' })
  rol: Rol;

  @Column({
    name: 'fecha_asignacion',
    type: 'timestamp',
    default: () => 'now()',
  })
  fechaAsignacion: Date;
}
