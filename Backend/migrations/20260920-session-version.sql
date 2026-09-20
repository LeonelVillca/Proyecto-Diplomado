BEGIN;
ALTER TABLE cuentas_auth ADD COLUMN IF NOT EXISTS session_version integer NOT NULL DEFAULT 0;
ALTER TABLE invitacion_token ADD COLUMN IF NOT EXISTS intentos_verificacion integer NOT NULL DEFAULT 0;
COMMIT;
