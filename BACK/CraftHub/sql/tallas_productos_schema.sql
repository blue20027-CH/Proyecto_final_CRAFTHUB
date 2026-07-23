-- Tallas disponibles de un producto (solo aplica a Vestir y Calzado).
-- Se guardan como texto separado por comas, ej: "S,M,L,XL" o "38,39,40".
alter table productos add column if not exists tallas text;
