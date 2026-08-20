import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('invitacion_token')
export class InvitacionToken {
  @PrimaryGeneratedColumn({ name: 'id_token' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ name: 'token', type: 'varchar', length: 255, unique: true })
  token: string;

  @Column({
    name: 'tipo',
    type: 'varchar',
    length: 30,
    default: 'invitacion',
  })
  tipo: string;

  @Column({ name: 'usado', type: 'boolean', default: false })
  usado: boolean;

  @Column({ name: 'fecha_creacion', type: 'timestamp', default: () => 'now()' })
  fechaCreacion: Date;

  @Column({ name: 'fecha_expiracion', type: 'timestamp' })
  fechaExpiracion: Date;
}
