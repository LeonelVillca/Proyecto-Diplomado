-- Normaliza el modelo y lleva a la base las reglas que el backend ya asume.
-- La transacción completa se revierte si existen duplicados o datos inválidos.
BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre varchar(255) PRIMARY KEY,
  aplicada_at timestamptz NOT NULL DEFAULT now()
);

-- Funcionalidades retiradas del producto.
DROP VIEW IF EXISTS vista_ranking_restaurantes;
DROP TABLE IF EXISTS notificacion;
DROP TABLE IF EXISTS visita;

-- Un único vocabulario para reservas.
UPDATE reservas SET estado = 'confirmada' WHERE estado = 'aprobada';
DROP INDEX IF EXISTS uq_reserva_mesa_horario_activa;
CREATE UNIQUE INDEX uq_reserva_mesa_horario_activa
  ON reservas (id_mesa, fecha, hora)
  WHERE estado IN ('pendiente', 'confirmada');

-- Convención única: 0=lunes, ..., 6=domingo.
-- Solo transforma restaurantes que todavía tengan el marcador legado 7=domingo.
WITH restaurantes_legacy AS (
  SELECT DISTINCT id_restaurante
  FROM horario_atencion
  WHERE dia_semana = 7
)
UPDATE horario_atencion AS h
SET dia_semana = h.dia_semana - 1
FROM restaurantes_legacy AS legacy
WHERE h.id_restaurante = legacy.id_restaurante;

-- Una foto principal por plato vive en plato.foto_url. Imagen queda solo para galerías.
WITH primera_imagen AS (
  SELECT DISTINCT ON (id_plato) id_plato, url
  FROM imagen
  WHERE id_plato IS NOT NULL
  ORDER BY id_plato, id_imagen
)
UPDATE plato AS p
SET foto_url = primera_imagen.url
FROM primera_imagen
WHERE p.id_plato = primera_imagen.id_plato
  AND p.foto_url IS NULL;

DELETE FROM imagen WHERE id_plato IS NOT NULL;
ALTER TABLE imagen DROP COLUMN id_plato;

-- Relaciones obligatorias según el modelo de dominio.
ALTER TABLE cuentas_auth ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE documento_adjunto ALTER COLUMN id_solicitud SET NOT NULL;
ALTER TABLE horario_atencion ALTER COLUMN id_restaurante SET NOT NULL;
ALTER TABLE imagen ALTER COLUMN id_restaurante SET NOT NULL;
ALTER TABLE invitacion_token ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE menu ALTER COLUMN id_restaurante SET NOT NULL;
ALTER TABLE mesa ALTER COLUMN id_restaurante SET NOT NULL;
ALTER TABLE oauth_cuenta ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE plato ALTER COLUMN id_menu SET NOT NULL;
ALTER TABLE resenas ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE resenas ALTER COLUMN id_restaurante SET NOT NULL;
ALTER TABLE reservas ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE reservas ALTER COLUMN id_mesa SET NOT NULL;
ALTER TABLE respuesta_resena ALTER COLUMN id_resena SET NOT NULL;
ALTER TABLE respuesta_resena ALTER COLUMN id_usuario_restaurante SET NOT NULL;
ALTER TABLE solicitud ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE soporte ALTER COLUMN id_usuario SET NOT NULL;
ALTER TABLE soporte ALTER COLUMN id_categoria_soporte SET NOT NULL;
ALTER TABLE ubicacion ALTER COLUMN id_restaurante SET NOT NULL;

-- Claves candidatas que evitan carreras y duplicados lógicos.
CREATE UNIQUE INDEX uq_cuentas_auth_usuario ON cuentas_auth (id_usuario);
CREATE UNIQUE INDEX uq_oauth_identidad ON oauth_cuenta (proveedor, proveedor_id);
CREATE UNIQUE INDEX uq_oauth_usuario_proveedor ON oauth_cuenta (id_usuario, proveedor);
CREATE UNIQUE INDEX uq_restaurante_solicitud ON restaurante (id_solicitud)
  WHERE id_solicitud IS NOT NULL;
CREATE UNIQUE INDEX uq_ubicacion_restaurante ON ubicacion (id_restaurante);
CREATE UNIQUE INDEX uq_mesa_restaurante_numero ON mesa (id_restaurante, numero_mesa);
CREATE UNIQUE INDEX uq_menu_restaurante_nombre ON menu (id_restaurante, nombre);
CREATE UNIQUE INDEX uq_horario_restaurante_franja
  ON horario_atencion (id_restaurante, dia_semana, hora_inicio, hora_fin);
CREATE UNIQUE INDEX uq_resena_usuario_restaurante ON resenas (id_usuario, id_restaurante);
CREATE UNIQUE INDEX uq_respuesta_por_resena ON respuesta_resena (id_resena);
CREATE UNIQUE INDEX uq_categoria_soporte_nombre ON categoria_soporte (nombre);
CREATE UNIQUE INDEX uq_solicitud_pendiente_usuario ON solicitud (id_usuario)
  WHERE estado = 'pendiente';

-- Reglas de dominio, también protegidas frente a scripts e importaciones directas.
ALTER TABLE horario_atencion
  ADD CONSTRAINT ck_horario_dia CHECK (dia_semana BETWEEN 0 AND 6);
ALTER TABLE mesa
  ADD CONSTRAINT ck_mesa_capacidad CHECK (capacidad IS NULL OR capacidad > 0),
  ADD CONSTRAINT ck_mesa_estado CHECK (estado IN ('libre', 'ocupada', 'reservada', 'inactiva'));
ALTER TABLE plato
  ADD CONSTRAINT ck_plato_precio CHECK (precio >= 0);
ALTER TABLE resenas
  ADD CONSTRAINT ck_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5);
ALTER TABLE reservas
  ADD CONSTRAINT ck_reserva_personas CHECK (numero_personas > 0),
  ADD CONSTRAINT ck_reserva_estado CHECK (estado IN ('pendiente', 'confirmada', 'rechazada', 'finalizada', 'cancelada'));
ALTER TABLE solicitud
  ADD CONSTRAINT ck_solicitud_estado CHECK (estado IN ('pendiente', 'aprobada', 'rechazada'));
ALTER TABLE soporte
  ADD CONSTRAINT ck_soporte_estado CHECK (estado IN ('pendiente', 'respondida'));
ALTER TABLE usuarios
  ADD CONSTRAINT ck_usuario_estado CHECK (estado IN ('activo', 'suspendido', 'eliminado'));
ALTER TABLE ubicacion
  ADD CONSTRAINT ck_ubicacion_coordenadas_pareadas
    CHECK ((latitud IS NULL) = (longitud IS NULL)),
  ADD CONSTRAINT ck_ubicacion_latitud CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
  ADD CONSTRAINT ck_ubicacion_longitud CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180);
ALTER TABLE cuentas_auth
  ADD CONSTRAINT ck_cuenta_intentos CHECK (intentos_fallidos >= 0),
  ADD CONSTRAINT ck_cuenta_session_version CHECK (session_version >= 0);
ALTER TABLE invitacion_token
  ADD CONSTRAINT ck_token_intentos CHECK (intentos_verificacion >= 0),
  ADD CONSTRAINT ck_token_expiracion CHECK (fecha_expiracion > fecha_creacion);

-- PostgreSQL no crea índices automáticamente para claves foráneas.
CREATE INDEX ix_documento_solicitud ON documento_adjunto (id_solicitud);
CREATE INDEX ix_horario_restaurante ON horario_atencion (id_restaurante);
CREATE INDEX ix_imagen_restaurante ON imagen (id_restaurante);
CREATE INDEX ix_invitacion_usuario ON invitacion_token (id_usuario);
CREATE INDEX ix_menu_restaurante ON menu (id_restaurante);
CREATE INDEX ix_plato_menu ON plato (id_menu);
CREATE INDEX ix_resenas_restaurante_fecha ON resenas (id_restaurante, fecha DESC);
CREATE INDEX ix_resenas_usuario_fecha ON resenas (id_usuario, fecha DESC);
CREATE INDEX ix_reservas_usuario_fecha ON reservas (id_usuario, fecha DESC);
CREATE INDEX ix_reservas_mesa_fecha ON reservas (id_mesa, fecha DESC);
CREATE INDEX ix_respuesta_usuario ON respuesta_resena (id_usuario_restaurante);
CREATE INDEX ix_soporte_usuario_fecha ON soporte (id_usuario, fecha_creacion DESC);
CREATE INDEX ix_soporte_categoria ON soporte (id_categoria_soporte);
CREATE INDEX ix_solicitud_usuario ON solicitud (id_usuario);
CREATE INDEX ix_usuario_rol_rol ON usuario_rol (id_rol);
CREATE INDEX ix_rol_permiso_permiso ON rol_permiso (id_permiso);

INSERT INTO schema_migrations (nombre)
VALUES ('20260921-normalizacion-integridad.sql')
ON CONFLICT DO NOTHING;

COMMIT;
