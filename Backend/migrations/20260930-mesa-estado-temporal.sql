BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre varchar(255) PRIMARY KEY,
  aplicada_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE mesa
  ADD COLUMN IF NOT EXISTS estado_hasta timestamptz;

-- Los estados manuales existentes dejan de bloquear mesas indefinidamente.
UPDATE mesa
SET estado_hasta = now() + INTERVAL '60 minutes'
WHERE estado IN ('ocupada', 'reservada')
  AND estado_hasta IS NULL;

CREATE INDEX IF NOT EXISTS ix_mesa_estado_hasta_manual
  ON mesa (estado_hasta)
  WHERE estado IN ('ocupada', 'reservada')
    AND estado_hasta IS NOT NULL;

INSERT INTO schema_migrations (nombre)
VALUES ('20260930-mesa-estado-temporal.sql')
ON CONFLICT (nombre) DO NOTHING;

COMMIT;
