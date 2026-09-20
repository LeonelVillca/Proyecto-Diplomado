-- Impide dos reservas activas para la misma mesa y franja, incluso con peticiones simultáneas.
-- Si existen duplicados previos, el índice fallará y deberán resolverse manualmente.
CREATE UNIQUE INDEX IF NOT EXISTS uq_reserva_mesa_horario_activa
ON reservas (id_mesa, fecha, hora)
WHERE estado IN ('pendiente', 'aprobada', 'confirmada');
