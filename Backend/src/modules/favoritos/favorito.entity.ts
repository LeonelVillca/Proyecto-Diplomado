import { Entity, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn } from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Entity('favoritos')
export class Favorito {
  @PrimaryGeneratedColumn({ name: 'id_favorito' })
  id: number;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_usuario' })
  usuario: Usuario;

  @ManyToOne(() => Restaurante, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_restaurante' })
  restaurante: Restaurante;

  @CreateDateColumn({ name: 'fecha_creacion' })
  fechaCreacion: Date;
}
