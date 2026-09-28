import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Reserva } from '../reservas/reserva.entity';

@Entity('notificacion')
export class Notificacion {
  @PrimaryGeneratedColumn({ name: 'id_notificacion', type: 'bigint' })
  id: string;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Reserva, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'id_reserva' })
  reserva: Reserva | null;

  @Column({ type: 'varchar', length: 30 })
  tipo: 'reserva_confirmada' | 'reserva_rechazada';

  @Column({ type: 'varchar', length: 120 })
  titulo: string;

  @Column({ type: 'text' })
  mensaje: string;

  @CreateDateColumn({ name: 'creada_at', type: 'timestamptz' })
  creadaAt: Date;

  @Column({ name: 'leida_at', type: 'timestamptz', nullable: true })
  leidaAt: Date | null;
}
