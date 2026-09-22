import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Resena } from '../resenas/resena.entity';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('respuesta_resena')
export class RespuestaResena {
  @PrimaryGeneratedColumn({ name: 'id_respuesta' })
  id: number;

  @ManyToOne(() => Resena, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_resena' })
  resena: Resena;

  @ManyToOne(() => Usuario, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'id_usuario_restaurante' })
  usuarioRestaurante: Usuario;

  @Column({ type: 'text' })
  texto: string;

  @CreateDateColumn({ name: 'fecha_respuesta' })
  fechaRespuesta: Date;
}
