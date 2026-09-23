import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('excepcion_horario')
export class ExcepcionHorario {
  @PrimaryGeneratedColumn({ name: 'id_excepcion' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ type: 'date' })
  fecha: string;

  @Column({ type: 'boolean', default: true })
  cerrado: boolean;

  @Column({ name: 'hora_inicio', type: 'time', nullable: true })
  horaInicio: string | null;

  @Column({ name: 'hora_fin', type: 'time', nullable: true })
  horaFin: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  motivo: string | null;
}
