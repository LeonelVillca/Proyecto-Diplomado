import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Plato } from '../plato/plato.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('imagen')
export class Imagen {
  @PrimaryGeneratedColumn({ name: 'id_imagen' })
  id!: number;

  @ManyToOne(() => Plato, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'id_plato' })
  plato!: Plato | null;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante!: Restaurante | null;

  @Column({ name: 'url', type: 'varchar', length: 255 })
  url!: string;
}