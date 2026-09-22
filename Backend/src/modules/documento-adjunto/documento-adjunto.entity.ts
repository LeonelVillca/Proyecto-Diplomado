import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Solicitud } from '../solicitud/solicitud.entity';

@Entity('documento_adjunto')
export class DocumentoAdjunto {
  @PrimaryGeneratedColumn({ name: 'id_documento' })
  id: number;

  @ManyToOne(() => Solicitud, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'id_solicitud' })
  solicitud: Solicitud;

  @Column({ name: 'tipo', type: 'varchar', length: 50 })
  tipo: string;

  @Column({ name: 'url', type: 'varchar', length: 255 })
  url: string;

  @Column({ name: 'fecha_carga', type: 'timestamp', default: () => 'now()' })
  fechaCarga: Date;
}
