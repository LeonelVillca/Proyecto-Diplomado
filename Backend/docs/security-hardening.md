# Endurecimiento de base de datos

## Orden de despliegue

1. Crear un respaldo cifrado y comprobar que puede restaurarse.
2. Configurar un usuario DDL separado mediante `DB_MIGRATION_USER` y
   `DB_MIGRATION_PASSWORD`.
3. Aplicar las migraciones:

   ```powershell
   npm run migrate:normalize -- --apply
   ```

4. Configurar un `DB_USER` exclusivo para la API, distinto del usuario DDL:

   ```powershell
   npm run db:configure-runtime-role -- --apply
   ```

5. Ejecutar `npm run preflight:prod`. El proceso rechaza conexiones sin SSL,
   migraciones pendientes, superusuarios y roles con capacidad de crear bases,
   roles u objetos en el esquema `public`.
6. Desplegar la API y ejecutar una prueba de reserva, cancelación, reseña y
   recuperación de contraseña.

La comprobación de datos puede repetirse sin modificar la base:

```powershell
npm run db:verify
```

## Respaldos

- No guardar volcados con datos reales en Git ni en carpetas públicas.
- Cifrar cada respaldo antes de subirlo a almacenamiento externo.
- Restringir lectura al personal autorizado y registrar las descargas.
- Conservar una política de rotación y probar restauraciones periódicamente.
- Para desarrollo, usar datos anonimizados; no reutilizar correos, teléfonos,
  CI, hashes o tokens de producción.

## Separación de usuarios PostgreSQL

- `DB_MIGRATION_USER`: propietario/DDL, usado solamente durante despliegues.
- `DB_USER`: cuenta de ejecución de la API, limitada a DML y sin permisos para
  modificar la tabla de auditoría salvo insertar y consultar.
- Ninguno debe ser el usuario predeterminado `postgres` en la aplicación.

## Operaciones destructivas de esta migración

`20260922-consistencia-seguridad.sql` elimina exclusivamente las cuentas de
demostración `restaurante1@mesachapaca.com` hasta
`restaurante20@mesachapaca.com`, sus restaurantes identificables y los datos
dependientes. La transacción completa se revierte ante cualquier error.
