import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('dispositivo_push')
export class DispositivoPush {
  @PrimaryGeneratedColumn({ name: 'id_dispositivo', type: 'bigint' })
  id: string;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ type: 'text', unique: true })
  token: string;

  @Column({ type: 'varchar', length: 12 })
  plataforma: 'android' | 'ios';

  @UpdateDateColumn({ name: 'actualizado_at', type: 'timestamptz' })
  actualizadoAt: Date;
}
