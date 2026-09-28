import {
  Column,
  DeleteDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  ManyToMany,
  JoinTable,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Solicitud } from '../solicitud/solicitud.entity';
import { TipoComida } from './tipo-comida.entity';

@Entity('restaurante')
export class Restaurante {
  @PrimaryGeneratedColumn({ name: 'id_restaurante' })
  id: number;

  @ManyToOne(() => Solicitud, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'id_solicitud' })
  solicitud: Solicitud | null;

  @Column({ name: 'nombre', type: 'varchar', length: 150 })
  nombre: string;

  @Column({ name: 'tipo_comida', type: 'varchar', length: 100, nullable: true })
  tipoComida: string | null;

  @ManyToMany(() => TipoComida)
  @JoinTable({
    name: 'restaurante_tipo_comida',
    joinColumn: { name: 'id_restaurante', referencedColumnName: 'id' },
    inverseJoinColumn: {
      name: 'id_tipo_comida',
      referencedColumnName: 'id',
    },
  })
  tiposComida: TipoComida[];

  @Column({ name: 'descripcion', type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ name: 'telefono', type: 'varchar', length: 20, nullable: true })
  telefono: string | null;

  @Column({ name: 'correo', type: 'varchar', length: 150, nullable: true })
  correo: string | null;

  @Column({
    name: 'foto_portada',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  fotoPortada: string | null;

  @Column({ name: 'logo', type: 'varchar', length: 255, nullable: true })
  logo: string | null;

  @Column({ name: 'estado', type: 'boolean', default: true })
  estado: boolean;

  @Column({
    name: 'zona_horaria',
    type: 'varchar',
    length: 64,
    default: 'America/La_Paz',
  })
  zonaHoraria: string;

  @UpdateDateColumn({ name: 'actualizado_at', type: 'timestamptz' })
  actualizadoAt: Date;

  @DeleteDateColumn({
    name: 'eliminado_at',
    type: 'timestamptz',
    nullable: true,
  })
  eliminadoAt: Date | null;
}
