BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre varchar(255) PRIMARY KEY,
  aplicada_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notificacion (
  id_notificacion bigserial PRIMARY KEY,
  id_usuario integer NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_reserva integer REFERENCES reservas(id_reserva) ON DELETE SET NULL,
  tipo varchar(30) NOT NULL CHECK (tipo IN ('reserva_confirmada', 'reserva_rechazada')),
  titulo varchar(120) NOT NULL,
  mensaje text NOT NULL,
  creada_at timestamptz NOT NULL DEFAULT now(),
  leida_at timestamptz
);

CREATE INDEX IF NOT EXISTS ix_notificacion_usuario_fecha
  ON notificacion (id_usuario, creada_at DESC);
CREATE INDEX IF NOT EXISTS ix_notificacion_usuario_no_leida
  ON notificacion (id_usuario) WHERE leida_at IS NULL;

CREATE TABLE IF NOT EXISTS dispositivo_push (
  id_dispositivo bigserial PRIMARY KEY,
  id_usuario integer NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  plataforma varchar(12) NOT NULL CHECK (plataforma IN ('android', 'ios')),
  actualizado_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_dispositivo_push_usuario
  ON dispositivo_push (id_usuario);

INSERT INTO schema_migrations (nombre)
VALUES ('20260928-notificaciones-reservas.sql')
ON CONFLICT DO NOTHING;

COMMIT;
