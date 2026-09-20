-- Conserva la fecha de la última creación aunque se elimine la reseña pública.
CREATE TABLE IF NOT EXISTS resena_creacion_control (
  id_usuario integer NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_restaurante integer NOT NULL REFERENCES restaurante(id_restaurante) ON DELETE CASCADE,
  ultima_creacion timestamptz NOT NULL,
  PRIMARY KEY (id_usuario, id_restaurante)
);

-- Backfill de las reseñas existentes; no restaura reseñas borradas antes de esta migración.
INSERT INTO resena_creacion_control (id_usuario, id_restaurante, ultima_creacion)
SELECT id_usuario, id_restaurante, MAX(fecha) FROM resenas
GROUP BY id_usuario, id_restaurante
ON CONFLICT (id_usuario, id_restaurante)
DO UPDATE SET ultima_creacion = GREATEST(resena_creacion_control.ultima_creacion, EXCLUDED.ultima_creacion);
