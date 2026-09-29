BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre varchar(255) PRIMARY KEY,
  aplicada_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mesa_bloqueo_horario (
  id_mesa integer NOT NULL REFERENCES mesa(id_mesa) ON DELETE CASCADE,
  fecha date NOT NULL,
  hora time NOT NULL,
  estado varchar(20) NOT NULL CHECK (estado IN ('ocupada', 'reservada')),
  PRIMARY KEY (id_mesa, fecha, hora)
);

CREATE INDEX IF NOT EXISTS ix_mesa_bloqueo_horario_intervalo
  ON mesa_bloqueo_horario (fecha, hora, id_mesa);

INSERT INTO schema_migrations (nombre)
VALUES ('20261001-mesa-bloqueos-horarios.sql')
ON CONFLICT (nombre) DO NOTHING;

COMMIT;
