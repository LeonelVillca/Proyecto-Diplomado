# Cierre de hallazgos antes de entregar E3

Estos cambios preparan la copia de trabajo. No rotan credenciales, no modifican
producción y no eliminan versiones históricas. No hacer force push ni limpiar
historial sin una decisión explícita del propietario del repositorio.

## JWT del script RNF-01

`test/rendimiento/rnf01.js` solo usa `__ENV.TOKEN` y falla si no se proporciona.
El JWT que estaba en HEAD tiene expiración 2026-10-01 18:16:19 UTC y ya expiró
al momento de esta revisión. No registrar ni versionar el token nuevo.

`POST /api/v1/auth/cerrar-sesiones`, autenticado como la cuenta afectada con una
sesión vigente, incrementa `cuentas_auth.session_version`. `JwtStrategy` rechaza
los JWT cuya versión no coincide. Esto revoca todas las sesiones del usuario.
No se ejecutó esa operación. La expiración de un token no demuestra que no haya
otras sesiones abiertas; revocarlas es una acción separada si se necesita.

## Firebase

El JSON histórico no está en HEAD y coincide con la regla ignorada
`**/*firebase-adminsdk*.json`. El propietario informó que ya rotó la clave.
Comprobar en Google Cloud > IAM y administración > Cuentas de servicio > cuenta
correspondiente > Claves que la clave antigua está eliminada o deshabilitada.
Crear una nueva clave JSON solo si falta un reemplazo operativo. Mantener el
archivo fuera del repositorio y actualizar manualmente el gestor de secretos
que utiliza el backend. No se realizaron acciones en Google Cloud ni Render.

Referencia: https://docs.cloud.google.com/iam/docs/keys-create-delete

## Cuenta inicial SQL

`scripts/cuenta-inicial-alina-valcazar.sql` es un procedimiento manual opcional;
no participa en el arranque normal. El código contiene una identidad específica
con correo personal; no se verificó si esa cuenta existe ni si es ficticia.
El hash fijo fue retirado. Si se utilizó esa contraseña en una cuenta activa,
cambiarla manualmente y revocar sus sesiones. No se cambió ninguna cuenta.

El script requiere el ajuste de sesión `mesa_chapaca.initial_password_hash` con
un hash bcrypt de costo 10 o superior. Debe generarse desde una contraseña nueva
de al menos 10 caracteres. No publicar ni pasar el hash mediante argumentos de
línea de comandos. Ejecutar solo por una persona autorizada para crear la cuenta.

Ejemplo para una herramienta Node local ejecutada desde Backend, con las
credenciales DB habituales y `INITIAL_ACCOUNT_PASSWORD` suministrada al proceso
por un mecanismo privado (sin editar .env ni registrar su valor):

```javascript
const { Client } = require('pg');
const bcrypt = require('bcryptjs');
const { readFileSync } = require('fs');
// Configurar el entorno de conexión por el mecanismo local autorizado.
const password = process.env.INITIAL_ACCOUNT_PASSWORD;
if (!password || password.length < 10) {
  throw new Error('Se requiere una contraseña nueva de al menos 10 caracteres');
}
const client = new Client({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
});
(async () => {
  try {
    await client.connect();
    const hash = await bcrypt.hash(password, 12);
    await client.query(
      "SELECT set_config('mesa_chapaca.initial_password_hash', $1, false)",
      [hash],
    );
    await client.query(readFileSync('scripts/cuenta-inicial-alina-valcazar.sql', 'utf8'));
  } finally {
    await client.end();
  }
})().catch(() => {
  console.error('No se completó la creación manual de la cuenta');
  process.exitCode = 1;
});
```

No ejecutar el procedimiento simplemente para verificarlo en producción.
La validación inicial aborta si falta el hash, antes de crear registros.

## Documentos privados

Los 24 PDF de `storage/privado/solicitudes` se conservaron localmente y se
retiraron únicamente del índice Git. `/Backend/storage/privado/` está ignorado.
No se inspeccionó su contenido ni se asumió que fueran ficticios. Estos archivos
no son necesarios para compilar o ejecutar las pruebas E3 aisladas, pero pueden
ser necesarios para consultar solicitudes locales: por eso no fueron borrados.

## Estado Git y publicación

Antes del commit, HEAD conserva el JWT, el hash fijo y los PDF. Después de
commitear esta remediación, dejarán de estar en la versión nueva, pero seguirán
en los commits anteriores. La clave Firebase ya está solo en el historial.
La rotación reduce el riesgo de acceso; no limpia el historial ni los datos
personales. Una entrega pública que exija historial limpio requiere acordar una
limpieza separada o publicar una copia nueva sin esos objetos históricos.
No se ejecutó ninguna de esas acciones.
## Búsqueda final en la copia de trabajo

Se revisaron 514 archivos de texto actuales, incluidos archivos nuevos no
ignorados. Se omitieron 337 archivos binarios o de más de 2 MB. No se encontraron
JWT literales, claves privadas, JSON de service account, hashes bcrypt fijos,
API keys Brevo ni URLs de base con credenciales en los textos revisados.
Las menciones de FIREBASE_PRIVATE_KEY, JWT_SECRET, DB_PASSWORD, DATABASE_URL,
BREVO_API_KEY y CLOUDINARY_API_SECRET son nombres de configuración; los campos
sensibles de .env.example están vacíos. No se leyó ni modificó .env en esta fase.

Se conservaron los siguientes literales de pruebas, sin publicar sus valores:

| Archivo | Tipo | Estado |
|---|---|---|
| Backend/src/core/config/security.config.spec.ts | Configuración de prueba | Fixture de validación de entorno |
| Backend/src/modules/auth/auth-access.http.spec.ts | Secreto de firma de prueba | Servicios/repositorios sustituidos en test |
| Backend/src/modules/auth/auth.http-security.spec.ts | Secreto de prueba | Test HTTP con servicios sustituidos |
| Backend/src/modules/auth/auth.security.spec.ts | Contraseña/configuración de prueba | Fixture con dobles de servicio |
| Backend/src/modules/auth/jwt.strategy.spec.ts | Secreto de firma de prueba | Fixture del guard |
| Backend/src/modules/mail/mail.service.spec.ts | Configuración de correo de prueba | Fixture de servicio, no credencial operativa verificada |
| Backend/test/e3/must.e3-spec.ts | Contraseña local E3 | Cuenta temporal en base aislada |
| Backend/test/e3/run.cjs | Contraseña local E3 | Configuración del clúster exclusivo de pruebas |

Esto no constituye una certificación de todos los binarios ni del historial.
HEAD aún contiene el JWT, hash fijo y 24 PDF hasta que se cree un commit de los
cambios preparados. No se realizó ese commit ni push.