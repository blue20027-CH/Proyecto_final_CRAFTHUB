-- ============================================================================
-- mensajes_publicacion_schema.sql
-- Agrega columnas a la tabla "mensajes" para guardar una "foto" (snapshot)
-- del producto compartido en el chat (tipo = 'publicacion'), en vez de solo
-- guardar su id. Sin esto, el mensaje se veía bien un instante (con los
-- datos que ya tenía la app en memoria) pero al recargar la conversación
-- desde el backend no había forma de reconstruir la tarjeta — el mensaje
-- quedaba como una burbuja vacía.
--
-- Cómo usarlo:
--   1. Abre tu proyecto en supabase.com → SQL Editor → New query.
--   2. Pega y ejecuta este archivo completo.
--   3. Verifica en Table Editor que "mensajes" tenga las columnas nuevas.
-- ============================================================================

alter table mensajes add column if not exists publicacion_titulo text;
alter table mensajes add column if not exists publicacion_imagen_url text;
alter table mensajes add column if not exists publicacion_precio numeric;
alter table mensajes add column if not exists publicacion_artesano text;
