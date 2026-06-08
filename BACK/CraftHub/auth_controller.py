import os
from supabase import create_client, Client

# ─── CONFIGURACIÓN DE SUPABASE ──────────────────────────────────────────
# Intentamos leer las credenciales desde variables de entorno, si no, usa tus strings directos
# ─── CONFIGURACIÓN DE SUPABASE ──────────────────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://tcezyirkglpihohuzrqo.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjZXp5aXJrZ2xwaWhvaHV6cnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MzczMDYsImV4cCI6MjA5MjIxMzMwNn0.oTlKV86XE3Cq7MMRZyySzWoDYzv2OBcPpwAIpgq-Kwk")

# Instanciamos el cliente de Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def login_usuario_supabase(email: str, password: str) -> dict:
    """
    Interactúa puramente con Supabase Auth y la tabla 'perfiles'.
    Retorna un diccionario con formato estandarizado para el main.py.
    """
    try:
        # 1. Intentar el inicio de sesión en Supabase Auth
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        
        # Si la respuesta no contiene sesión o usuario válido
        if not auth_response.session or not auth_response.user:
            return {
                "status": "error",
                "message": "Credenciales incorrectas"
            }
            
        user_id = auth_response.user.id
        access_token = auth_response.session.access_token

        # 2. Consultar los datos extendidos en la tabla 'perfiles'
        perfil_resp = supabase.table("perfiles").select("nombre", "rol", "foto_perfil").eq("user_id", user_id).execute()
        
        # Valores por defecto por si el usuario no tiene fila en la tabla perfiles
        nombre = "Usuario CraftHub"
        rol = "comprador"
        foto_perfil = None
        
        if perfil_resp.data:
            perfil = perfil_resp.data[0]
            nombre = perfil.get("nombre", nombre)
            # Pasamos el rol a minúsculas para cumplir el contrato exacto ("vendedor" / "comprador")
            rol = str(perfil.get("rol", rol)).lower()
            foto_perfil = perfil.get("foto_perfil")

        # 3. Respuesta estructurada exitosa
        return {
            "status": "success",
            "access_token": access_token,
            "rol": rol,
            "nombre": nombre,
            "email": auth_response.user.email,
            "foto_perfil": foto_perfil
        }

    except Exception as ex:
        msg = str(ex).lower()
        # Capturamos el error común de credenciales de Supabase
        if "invalid login credentials" in msg or "bad credentials" in msg:
            return {
                "status": "error",
                "message": "Credenciales incorrectas"
            }
        
        # Manejo de cualquier otro error de conexión o base de datos
        return {
            "status": "error",
            "message": f"Error interno en Supabase: {str(ex)}"
        }