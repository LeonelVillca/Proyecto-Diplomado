import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Reserva } from '../reservas/reserva.entity';

@Entity('resenas')
export class Resena {
  @PrimaryGeneratedColumn({ name: 'id_resena' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @ManyToOne(() => Reserva, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'id_reserva' })
  reserva: Reserva | null;

  @Column({ type: 'text', nullable: true })
  comentario: string;

  @Column({ type: 'smallint' })
  calificacion: number;

  @CreateDateColumn({ name: 'fecha' })
  fecha: Date;
}
