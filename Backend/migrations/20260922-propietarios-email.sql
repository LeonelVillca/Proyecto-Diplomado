-- Recupera propietarios de restaurantes antiguos creados sin solicitud,
-- únicamente cuando el correo coincide exactamente con un único usuario.
BEGIN;

INSERT INTO usuario_restaurante (
  id_usuario,
  id_restaurante,
  rol,
  activo
)
SELECT min(u.id_usuario), r.id_restaurante, 'propietario', true
FROM restaurante r
JOIN usuarios u ON lower(u.correo) = lower(r.correo)
LEFT JOIN usuario_restaurante ur ON ur.id_restaurante = r.id_restaurante
WHERE r.eliminado_at IS NULL
  AND ur.id_restaurante IS NULL
GROUP BY r.id_restaurante
HAVING count(u.id_usuario) = 1
ON CONFLICT DO NOTHING;

INSERT INTO schema_migrations (nombre)
VALUES ('20260922-propietarios-email.sql')
ON CONFLICT DO NOTHING;

COMMIT;
