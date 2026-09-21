-- Actualiza las URLs de imágenes públicas migradas de JPG/PNG a WebP.
-- Los archivos correspondientes deben desplegarse junto con esta migración.
UPDATE restaurante
SET foto_portada = regexp_replace(foto_portada, '\\.(jpe?g|png)$', '.webp', 'i')
WHERE foto_portada ~ '^/publico/'
  AND foto_portada ~* '\\.(jpe?g|png)$';

UPDATE restaurante
SET logo = regexp_replace(logo, '\\.(jpe?g|png)$', '.webp', 'i')
WHERE logo ~ '^/publico/'
  AND logo ~* '\\.(jpe?g|png)$';

UPDATE plato
SET foto_url = regexp_replace(foto_url, '\\.(jpe?g|png)$', '.webp', 'i')
WHERE foto_url ~ '^/publico/'
  AND foto_url ~* '\\.(jpe?g|png)$';

UPDATE imagen
SET url = regexp_replace(url, '\\.(jpe?g|png)$', '.webp', 'i')
WHERE url ~ '^/publico/'
  AND url ~* '\\.(jpe?g|png)$';
