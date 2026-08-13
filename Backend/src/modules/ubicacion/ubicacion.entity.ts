import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('ubicacion')
export class Ubicacion {
  @PrimaryGeneratedColumn({ name: 'id_ubicacion' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ name: 'direccion', type: 'varchar', length: 255, nullable: true })
  direccion: string | null;

  @Column({ name: 'latitud', type: 'double precision', nullable: true })
  latitud: number | null;

  @Column({ name: 'longitud', type: 'double precision', nullable: true })
  longitud: number | null;
}