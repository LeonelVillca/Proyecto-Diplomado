import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('resenas')
export class Resena {
  @PrimaryGeneratedColumn({ name: 'id_resena' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @Column({ type: 'text', nullable: true })
  comentario: string;

  @Column({ type: 'smallint' })
  calificacion: number;

  @CreateDateColumn({ name: 'fecha' })
  fecha: Date;
}
