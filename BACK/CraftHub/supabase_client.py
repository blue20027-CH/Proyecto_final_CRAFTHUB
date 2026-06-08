import os
from supabase import create_client, Client

# Intentamos leer desde el entorno, de lo contrario usamos tus valores actuales por defecto
SUPABASE_URL = os.getenv(
    "SUPABASE_URL",
    "https://tcezyirkglpihohuzrqo.supabase.co",
)

SUPABASE_KEY = os.getenv(
    "SUPABASE_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjZXp5aXJrZ2xwaWhvaHV6cnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MzczMDYsImV4cCI6MjA5MjIxMzMwNn0.oTlKV86XE3Cq7MMRZyySzWoDYzv2OBcPpwAIpgq-Kwk",
)

# Instancia única del cliente de Supabase que importaremos en los controladores de la API
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)