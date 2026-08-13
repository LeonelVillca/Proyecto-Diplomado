import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('visita')
export class Visita {
  @PrimaryGeneratedColumn({ name: 'id_visita' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @ManyToOne(() => Usuario, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario | null;

  @Column({ name: 'fecha_hora', type: 'timestamp', default: () => 'now()' })
  fechaHora: Date;
}