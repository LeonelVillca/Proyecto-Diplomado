-- Las solicitudes anteriores se conservan como verificadas una sola vez.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema() AND table_name = 'solicitud'
      AND column_name = 'correo_verificado_at'
  ) THEN
    ALTER TABLE solicitud ADD COLUMN correo_verificado_at timestamptz;
    UPDATE solicitud SET correo_verificado_at = NOW();
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS solicitud_verificacion (
  id_solicitud integer PRIMARY KEY REFERENCES solicitud(id_solicitud) ON DELETE CASCADE,
  token_hash char(64) NOT NULL UNIQUE,
  expira_at timestamptz NOT NULL,
  enviado_at timestamptz
);
