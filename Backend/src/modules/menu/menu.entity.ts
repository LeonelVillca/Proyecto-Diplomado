import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Plato } from '../plato/plato.entity';

@Entity('menu')
export class Menu {
  @PrimaryGeneratedColumn({ name: 'id_menu' })
  id: number;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ name: 'nombre', type: 'varchar', length: 100 })
  nombre: string;

  @Column({ name: 'descripcion', type: 'varchar', length: 255, nullable: true })
  descripcion: string | null;

  @Column({ name: 'tipo', type: 'varchar', length: 50, nullable: true })
  tipo: string | null;

  @Column({ name: 'disponibilidad', type: 'boolean', default: true })
  disponibilidad: boolean;

  @OneToMany(() => Plato, plato => plato.menu)
  platos: Plato[];
}