import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('tipo_comida')
export class TipoComida {
  @PrimaryGeneratedColumn({ name: 'id_tipo_comida' })
  id: number;

  @Column({ name: 'nombre', type: 'varchar', length: 100, unique: true })
  nombre: string;

  @Column({ name: 'slug', type: 'varchar', length: 100, unique: true })
  slug: string;

  @Column({ name: 'activo', type: 'boolean', default: true })
  activo: boolean;
}
