import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('categoria_soporte')
export class CategoriaSoporte {
  @PrimaryGeneratedColumn({ name: 'id_categoria' })
  id: number;

  @Column({ name: 'nombre', type: 'varchar', length: 100 })
  nombre: string;

  @Column({ name: 'descripcion', type: 'varchar', length: 255, nullable: true })
  descripcion: string | null;
}