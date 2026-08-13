import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { CategoriaSoporte } from '../categoria-soporte/categoria-soporte.entity';

export const ESTADO_SOPORTE = ['pendiente', 'respondida'] as const;

@Entity('soporte')
export class Soporte {
  @PrimaryGeneratedColumn({ name: 'id_soporte' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => CategoriaSoporte, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'id_categoria_soporte' })
  categoriaSoporte: CategoriaSoporte;

  @Column({ name: 'asunto', type: 'varchar', length: 150 })
  asunto: string;

  @Column({ name: 'descripcion', type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'pendiente' })
  estado: (typeof ESTADO_SOPORTE)[number];

  @Column({ name: 'respuesta', type: 'text', nullable: true })
  respuesta: string | null;

  @Column({ name: 'fecha_creacion', type: 'timestamp', default: () => 'now()' })
  fechaCreacion: Date;

  @Column({ name: 'fecha_respuesta', type: 'timestamp', nullable: true })
  fechaRespuesta: Date | null;
}