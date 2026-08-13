import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';

export const ESTADO_MESA = ['libre', 'ocupada', 'reservada', 'inactiva'] as const;

@Entity('mesa')
export class Mesa {
  @PrimaryGeneratedColumn({ name: 'id_mesa' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ name: 'numero_mesa', type: 'varchar', length: 20 })
  numeroMesa: string;

  @Column({ name: 'capacidad', type: 'int', nullable: true })
  capacidad: number | null;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'libre' })
  estado: (typeof ESTADO_MESA)[number];
}