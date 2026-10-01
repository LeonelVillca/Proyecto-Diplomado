-- Cuenta directa para completar un perfil desde el onboarding.
-- Ejecutar una sola vez en Neon, en la base de datos que usa la API.
-- Si el correo ya existe, el bloque se detiene sin modificar esa cuenta.
BEGIN;

-- El hash se aporta solo para esta sesión mediante set_config parametrizado.
-- Ver Backend/docs/secrets-remediation.md. No almacenar el hash en este archivo.
DO $validar_hash$
BEGIN
  IF COALESCE(current_setting('mesa_chapaca.initial_password_hash', true), '')
     !~ '^\$2[aby]\$(1[0-9]|2[0-9]|3[01])\$[./A-Za-z0-9]{53}$' THEN
    RAISE EXCEPTION 'Falta un hash bcrypt válido para la cuenta inicial; no se creó ninguna cuenta';
  END IF;
END
$validar_hash$;

INSERT INTO public.rol (nombre, descripcion)
VALUES ('admin_restaurante', 'Administración de restaurante')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO public.permiso (codigo, descripcion)
VALUES
  ('menu_dashboard', 'Acceso al Dashboard general'),
  ('menu_perfil_restaurante', 'Configurar datos del restaurante'),
  ('menu_mesas', 'Gestión de mesas y horarios'),
  ('menu_menus', 'Gestión de platillos y menú'),
  ('menu_reservas', 'Gestión de reservas entrantes'),
  ('menu_resenas', 'Ver y responder reseñas'),
  ('menu_soporte', 'Centro de ayuda y tickets')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM public.rol r
CROSS JOIN public.permiso p
WHERE r.nombre = 'admin_restaurante'
  AND p.codigo IN (
    'menu_dashboard',
    'menu_perfil_restaurante',
    'menu_mesas',
    'menu_menus',
    'menu_reservas',
    'menu_resenas',
    'menu_soporte'
  )
ON CONFLICT (id_rol, id_permiso) DO NOTHING;

DO $cuenta$
DECLARE
  v_usuario_id integer;
  v_rol_id integer;
  v_solicitud_id integer;
  v_restaurante_id integer;
  v_correo constant text := 'alina.valcazar.63827@gmail.com';
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.usuarios WHERE lower(correo) = lower(v_correo)
  ) THEN
    RAISE EXCEPTION 'El correo % ya existe; no se modificó ninguna cuenta', v_correo;
  END IF;

  INSERT INTO public.usuarios (nombre, apellido, correo, estado, eliminado_at)
  VALUES ('Alina', 'Valcázar', v_correo, 'activo', NULL)
  RETURNING id_usuario INTO v_usuario_id;

  INSERT INTO public.cuentas_auth
    (id_usuario, password_hash, intentos_fallidos, estado, session_version)
  VALUES
    (v_usuario_id, current_setting('mesa_chapaca.initial_password_hash'), 0, TRUE, 0);

  SELECT id_rol INTO v_rol_id
    FROM public.rol
   WHERE nombre = 'admin_restaurante';

  INSERT INTO public.usuario_rol (id_usuario, id_rol)
  VALUES (v_usuario_id, v_rol_id)
  ON CONFLICT (id_usuario, id_rol) DO NOTHING;

  -- La solicitud se marca aprobada directamente para abrir el onboarding sin
  -- pasar por la solicitud pública, revisión de documentos ni invitación.
  INSERT INTO public.solicitud
    (id_usuario, estado, nombre_restaurante, correo_verificado_at)
  VALUES
    (v_usuario_id, 'aprobada', 'Casa Valcázar', NOW())
  RETURNING id_solicitud INTO v_solicitud_id;

  INSERT INTO public.restaurante
    (id_solicitud, nombre, correo, estado, tipo_comida, descripcion,
     telefono, foto_portada, logo, eliminado_at)
  VALUES
    (v_solicitud_id, 'Casa Valcázar', v_correo, FALSE, NULL, NULL,
     NULL, NULL, NULL, NULL)
  RETURNING id_restaurante INTO v_restaurante_id;

  INSERT INTO public.usuario_restaurante (id_usuario, id_restaurante, rol, activo)
  VALUES (v_usuario_id, v_restaurante_id, 'propietario', TRUE);
END
$cuenta$;

COMMIT;
