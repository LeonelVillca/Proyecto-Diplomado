export interface UsuarioPublico {
  id: number;
  nombre: string;
  apellido: string | null;
  correo: string;
  roles?: string[];
}
