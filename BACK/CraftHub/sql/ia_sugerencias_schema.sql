-- Feedback de las sugerencias de nombres generadas por la IA: qué aceptó y
-- qué rechazó cada vendedor. Es la base de datos de entrenamiento del
-- componente de Machine Learning (ml_tonos.py) que aprende qué tono funciona
-- mejor por categoría de artesanía.
create table if not exists ia_sugerencias (
  id uuid primary key default gen_random_uuid(),
  vendedor_nombre text not null,
  categoria text,
  personalidad text,
  sugerencia text not null,
  aceptada boolean not null default false,
  created_at timestamptz not null default now()
);

alter table ia_sugerencias enable row level security;
create policy "ia_sugerencias_todo" on ia_sugerencias for all using (true) with check (true);
