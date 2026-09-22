import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('imagen')
export class Imagen {
  @PrimaryGeneratedColumn({ name: 'id_imagen' })
  id!: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante!: Restaurante;

  @Column({ name: 'url', type: 'varchar', length: 255 })
  url!: string;
}
