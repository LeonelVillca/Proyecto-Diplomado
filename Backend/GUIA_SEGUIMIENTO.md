# GUIA_SEGUIMIENTO — Mesa Chapaca

## Seguridad de autenticación

- **14/09/2026:** eliminado el registro local público
  `POST /api/v1/auth/register`. Ese endpoint podía reutilizar una cuenta
  existente y emitir un JWT sin comprobar contraseña ni invitación.
- Acceso de cliente: exclusivamente `POST /api/v1/auth/google`, con ID Token
  verificado server-side mediante Firebase Admin.
- Acceso administrativo: creación inicial de contraseña exclusivamente con
  token de invitación; sesiones posteriores mediante `POST /api/v1/auth/login`.
