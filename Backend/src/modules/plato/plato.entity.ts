import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Menu } from '../menu/menu.entity';

@Entity('plato')
export class Plato {
  @PrimaryGeneratedColumn({ name: 'id_plato' })
  id: number;

  @ManyToOne(() => Menu, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_menu' })
  menu: Menu;

  @Column({ name: 'nombre', type: 'varchar', length: 150 })
  nombre: string;

  @Column({
    name: 'precio',
    type: 'numeric',
    transformer: {
      to: (value: number) => value,
      from: (value: unknown) =>
        typeof value === 'string' ? parseFloat(value) : value,
    },
  })
  precio: number;

  @Column({ name: 'descripcion', type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ name: 'disponible', type: 'boolean', default: true })
  disponible: boolean;

  @Column({ name: 'foto_url', type: 'varchar', nullable: true })
  fotoUrl: string | null;
}
