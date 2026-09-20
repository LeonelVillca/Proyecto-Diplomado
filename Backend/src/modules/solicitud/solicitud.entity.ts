import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { DocumentoAdjunto } from '../documento-adjunto/documento-adjunto.entity';

export const ESTADO_SOLICITUD = ['pendiente', 'aprobada', 'rechazada'] as const;

@Entity('solicitud')
export class Solicitud {
  @PrimaryGeneratedColumn({ name: 'id_solicitud' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @OneToMany(() => DocumentoAdjunto, (doc) => doc.solicitud)
  documentosAdjuntos: DocumentoAdjunto[];

  @Column({ name: 'fecha', type: 'date', default: () => 'CURRENT_DATE' })
  fecha: string;

  @Column({
    name: 'estado',
    type: 'varchar',
    length: 20,
    default: 'pendiente',
  })
  estado: (typeof ESTADO_SOLICITUD)[number];

  @Column({ name: 'correo_verificado_at', type: 'timestamptz', nullable: true })
  correoVerificadoAt: Date | null;

  @Column({ name: 'nombre_restaurante', type: 'varchar', length: 150 })
  nombreRestaurante: string;

  @Column({ name: 'tipo_comida', type: 'varchar', length: 100, nullable: true })
  tipoComida: string | null;

  @Column({ name: 'nit_negocio', type: 'varchar', length: 30, nullable: true })
  nitNegocio: string | null;

  @Column({ name: 'celular_contacto', type: 'varchar', length: 20, nullable: true })
  celularContacto: string | null;

  @Column({ name: 'descripcion', type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ name: 'horarios_atencion', type: 'varchar', length: 255, nullable: true })
  horariosAtencion: string | null;

  @Column({ name: 'motivo_rechazo', type: 'varchar', length: 255, nullable: true })
  motivoRechazo: string | null;
}
