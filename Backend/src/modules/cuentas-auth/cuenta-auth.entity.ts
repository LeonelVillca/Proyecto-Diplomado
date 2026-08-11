import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('cuentas_auth')
export class CuentaAuth {
  @PrimaryGeneratedColumn({ name: 'id_cuenta' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ name: 'password_hash', type: 'varchar', length: 255, nullable: true })
  passwordHash: string | null;

  @Column({ name: 'ultimo_ingreso', type: 'timestamp', nullable: true })
  ultimoIngreso: Date | null;

  @Column({ name: 'intentos_fallidos', type: 'int', default: 0 })
  intentosFallidos: number;

  @Column({ name: 'estado', type: 'boolean', default: true })
  estado: boolean;
}