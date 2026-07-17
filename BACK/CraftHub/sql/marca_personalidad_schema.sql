-- Personalidad de marca del vendedor: define el tono con el que la IA
-- redacta sus nombres y descripciones de producto (Elegante, Amigable, etc.)
alter table perfiles add column if not exists marca_personalidad text;
