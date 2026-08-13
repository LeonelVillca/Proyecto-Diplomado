import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('notificacion')
export class Notificacion {
  @PrimaryGeneratedColumn({ name: 'id_notificacion' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ name: 'tipo', type: 'varchar', length: 30 })
  tipo: string;

  @Column({ name: 'mensaje', type: 'text' })
  mensaje: string;

  @Column({ name: 'leido', type: 'boolean', default: false })
  leido: boolean;

  @Column({ name: 'fecha_envio', type: 'timestamp', default: () => 'now()' })
  fechaEnvio: Date;
}