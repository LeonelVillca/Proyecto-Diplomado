import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';

@Entity('oauth_cuenta')
export class OauthCuenta {
  @PrimaryGeneratedColumn({ name: 'id_oauth' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @Column({ name: 'proveedor', type: 'varchar', length: 30 })
  proveedor: string;

  @Column({ name: 'proveedor_id', type: 'varchar', length: 255 })
  proveedorId: string;

  @Column({ name: 'email_verificado', type: 'boolean', default: false })
  emailVerificado: boolean;
}