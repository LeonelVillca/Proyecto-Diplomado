import {
  Column,
  DeleteDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('usuarios')
export class Usuario {
  @PrimaryGeneratedColumn({ name: 'id_usuario' })
  id: number;

  @Column({ name: 'nombre', type: 'varchar', length: 100 })
  nombre: string;

  @Column({ name: 'apellido', type: 'varchar', length: 100, nullable: true })
  apellido: string | null;

  @Column({ name: 'correo', type: 'varchar', length: 150, unique: true })
  correo: string;

  @Column({
    name: 'ci',
    type: 'varchar',
    length: 20,
    unique: true,
    nullable: true,
  })
  ci: string | null;

  @Column({ name: 'fecha_nacimiento', type: 'date', nullable: true })
  fechaNacimiento: string | null;

  @Column({ name: 'foto', type: 'varchar', length: 255, nullable: true })
  foto: string | null;

  @Column({ name: 'telefono', type: 'varchar', length: 20, nullable: true })
  telefono: string | null;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'activo' })
  estado: string;

  @Column({ name: 'fecha_registro', type: 'timestamp', default: () => 'now()' })
  fechaRegistro: Date;

  @UpdateDateColumn({ name: 'actualizado_at', type: 'timestamptz' })
  actualizadoAt: Date;

  @DeleteDateColumn({
    name: 'eliminado_at',
    type: 'timestamptz',
    nullable: true,
  })
  eliminadoAt: Date | null;
}
