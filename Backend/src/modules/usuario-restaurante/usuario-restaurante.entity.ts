import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('usuario_restaurante')
export class UsuarioRestaurante {
  @PrimaryColumn({ name: 'id_usuario', type: 'int' })
  idUsuario: number;

  @PrimaryColumn({ name: 'id_restaurante', type: 'int' })
  idRestaurante: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ type: 'varchar', length: 20, default: 'propietario' })
  rol: 'propietario' | 'administrador' | 'empleado';

  @Column({ type: 'boolean', default: true })
  activo: boolean;

  @CreateDateColumn({ name: 'fecha_asignacion', type: 'timestamptz' })
  fechaAsignacion: Date;
}
