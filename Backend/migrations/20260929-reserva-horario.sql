BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre varchar(255) PRIMARY KEY,
  aplicada_at timestamptz NOT NULL DEFAULT now()
);

-- Antes de cambiar la duración y aplicar el margen previo, detectar horarios
-- activos incompatibles para que la migración falle sin modificar los datos.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM reservas a
    JOIN reservas b
      ON b.id_mesa = a.id_mesa
     AND b.id_reserva > a.id_reserva
     AND b.estado IN ('pendiente', 'confirmada')
    WHERE a.estado IN ('pendiente', 'confirmada')
      AND tsrange(
        a.fecha + a.hora - INTERVAL '30 minutes',
        a.fecha + a.hora + INTERVAL '60 minutes',
        '[)'
      ) && tsrange(
        b.fecha + b.hora,
        b.fecha + b.hora + INTERVAL '60 minutes',
        '[)'
      )
  ) THEN
    RAISE EXCEPTION
      'Hay reservas activas de la misma mesa que chocan con la nueva duración de 1 hora y el margen de 30 minutos. Revisa los horarios antes de volver a ejecutar la migración.';
  END IF;
END;
$$;

ALTER TABLE reservas
  DROP CONSTRAINT IF EXISTS ex_reserva_mesa_intervalo_activo;

UPDATE reservas
SET duracion_minutos = 60
WHERE duracion_minutos <> 60;

ALTER TABLE reservas
  ALTER COLUMN duracion_minutos SET DEFAULT 60,
  DROP CONSTRAINT IF EXISTS ck_reserva_duracion;

ALTER TABLE reservas
  ADD CONSTRAINT ck_reserva_duracion CHECK (duracion_minutos = 60);

ALTER TABLE reservas
  ADD CONSTRAINT ex_reserva_mesa_intervalo_activo
    EXCLUDE USING gist (
      id_mesa WITH =,
      tsrange(
        fecha + hora,
        fecha + hora + (duracion_minutos * INTERVAL '1 minute'),
        '[)'
      ) WITH &&
    )
    WHERE (estado IN ('pendiente', 'confirmada'));

INSERT INTO schema_migrations (nombre)
VALUES ('20260929-reserva-horario.sql')
ON CONFLICT (nombre) DO NOTHING;

COMMIT;
