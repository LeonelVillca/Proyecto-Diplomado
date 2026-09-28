BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  nombre VARCHAR(255) PRIMARY KEY,
  aplicada_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tipo_comida (
  id_tipo_comida SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  slug VARCHAR(100) NOT NULL UNIQUE,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS restaurante_tipo_comida (
  id_restaurante INTEGER NOT NULL REFERENCES restaurante(id_restaurante) ON DELETE CASCADE,
  id_tipo_comida INTEGER NOT NULL REFERENCES tipo_comida(id_tipo_comida) ON DELETE CASCADE,
  PRIMARY KEY (id_restaurante, id_tipo_comida)
);

INSERT INTO tipo_comida (nombre, slug) VALUES
  ('Tarijeña o chapaca', 'tarijena-chapaca'),
  ('Comida boliviana', 'boliviana'),
  ('Parrilla y churrasquería', 'parrilla-churrasqueria'),
  ('Pescados y mariscos', 'pescados-mariscos'),
  ('Comida rápida', 'comida-rapida'),
  ('Hamburguesas', 'hamburguesas'),
  ('Pizzería', 'pizzeria'),
  ('Salteñería y empanadas', 'saltenas-empanadas'),
  ('Italiana', 'italiana'),
  ('Mexicana', 'mexicana'),
  ('China', 'china'),
  ('Coreana y asiática', 'coreana-asiatica'),
  ('Peruana', 'peruana'),
  ('Internacional o fusión', 'internacional-fusion'),
  ('Cafetería y bistró', 'cafeteria-bistro'),
  ('Panadería y pastelería', 'panaderia-pasteleria'),
  ('Heladería y postres', 'heladeria-postres'),
  ('Vegetariana y comida natural', 'vegetariana-natural'),
  ('Vino y bar', 'vino-bar'),
  ('Por definir', 'por-definir')
ON CONFLICT (slug) DO NOTHING;

-- Backfill every existing restaurant. Map recognizable free-text values and
-- leave ambiguous or empty values editable as "Por definir" in its profile.
WITH clasificacion AS (
  SELECT r.id_restaurante,
    CASE
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'tarij|chapac|regional|tipic|t[ií]pic' THEN 'tarijena-chapaca'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'hamburg|burger' THEN 'hamburguesas'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'pizza' THEN 'pizzeria'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'salte[nñ]|empanad' THEN 'saltenas-empanadas'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'pescad|marisc|cevich|s[aá]balo|pac[uú]' THEN 'pescados-mariscos'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'parrill|churras|carne|asado' THEN 'parrilla-churrasqueria'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'mexic|taco' THEN 'mexicana'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'core|asi[aá]t|japon|sushi|ramen' THEN 'coreana-asiatica'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'china|chifa|chaufa|chop suey' THEN 'china'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'per[uú]|ceviche' THEN 'peruana'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'ital|pasta|pastas|lasagna|lasa[nñ]a' THEN 'italiana'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'caf[eé]|bistr[oó]|coffee' THEN 'cafeteria-bistro'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'vino|bar' THEN 'vino-bar'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'panader|pasteler|torta|reposter' THEN 'panaderia-pasteleria'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'helad|postre|dulce' THEN 'heladeria-postres'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'veget|natural|saludable|healthy' THEN 'vegetariana-natural'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'r[aá]pida|lomito|salchip|pique|pollo' THEN 'comida-rapida'
      WHEN lower(coalesce(r.tipo_comida, '')) ~ 'boliv|nacional|criolla' THEN 'boliviana'
      WHEN nullif(trim(r.tipo_comida), '') IS NULL THEN 'por-definir'
      ELSE 'por-definir'
    END AS slug
  FROM restaurante r
), seleccion AS (
  SELECT c.id_restaurante, t.id_tipo_comida
  FROM clasificacion c
  JOIN tipo_comida t ON t.slug = c.slug
)
INSERT INTO restaurante_tipo_comida (id_restaurante, id_tipo_comida)
SELECT id_restaurante, id_tipo_comida FROM seleccion
ON CONFLICT DO NOTHING;

INSERT INTO schema_migrations (nombre)
VALUES ('20260928-tipos-comida.sql')
ON CONFLICT DO NOTHING;

COMMIT;

-- Rollback:
-- BEGIN;
-- DROP TABLE IF EXISTS restaurante_tipo_comida;
-- DROP TABLE IF EXISTS tipo_comida;
-- COMMIT;
