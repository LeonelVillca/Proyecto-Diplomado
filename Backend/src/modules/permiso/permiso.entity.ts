import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('permiso')
export class Permiso {
  @PrimaryGeneratedColumn({ name: 'id_permiso' })
  id: number;

  @Column({ name: 'codigo', type: 'varchar', length: 80, unique: true })
  codigo: string;

  @Column({ name: 'descripcion', type: 'varchar', length: 255, nullable: true })
  descripcion: string | null;
}
