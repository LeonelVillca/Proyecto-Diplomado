import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Mesa } from '../mesa/mesa.entity';

@Entity('reservas')
export class Reserva {
  @PrimaryGeneratedColumn({ name: 'id_reserva' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Mesa, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'id_mesa' })
  mesa: Mesa;

  @Column({ type: 'date' })
  fecha: string;

  @Column({ type: 'time' })
  hora: string;

  @Column({ name: 'duracion_minutos', type: 'int', default: 120 })
  duracionMinutos: number;

  @Column({ name: 'numero_personas', type: 'int' })
  numeroPersonas: number;

  @Column({ type: 'varchar', length: 20, default: 'pendiente' })
  estado: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  comentarios: string;

  @CreateDateColumn({ name: 'fecha_creacion' })
  fechaCreacion: Date;

  @UpdateDateColumn({ name: 'actualizado_at', type: 'timestamptz' })
  actualizadoAt: Date;
}
