import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('reportes')
export class Reporte {
  @PrimaryGeneratedColumn({ name: 'id_reporte' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ name: 'tipo', type: 'varchar', length: 50 })
  tipo: string;

  @Column({ name: 'fecha_inicio', type: 'date', nullable: true })
  fechaInicio: string | null;

  @Column({ name: 'fecha_fin', type: 'date', nullable: true })
  fechaFin: string | null;

  @Column({ name: 'estado', type: 'varchar', length: 20, nullable: true })
  estado: string | null;

  @Column({ name: 'fecha_creacion', type: 'timestamp', default: () => 'now()' })
  fechaCreacion: Date;
}