import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('horario_atencion')
export class HorarioAtencion {
  @PrimaryGeneratedColumn({ name: 'id_horario' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ name: 'dia_semana', type: 'smallint' })
  diaSemana: number;

  @Column({ name: 'hora_inicio', type: 'time' })
  horaInicio: string;

  @Column({ name: 'hora_fin', type: 'time' })
  horaFin: string;
}
