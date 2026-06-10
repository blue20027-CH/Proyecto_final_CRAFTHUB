import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase


def login_usuario_supabase(email: str, password: str) -> dict:
    """
    Autentica al usuario en Supabase Auth y obtiene su perfil.
    🔗 FLUTTER: consumido desde /api/auth/login en main.py
    """
    try:
        # Paso 1: Autenticar credenciales en Supabase Auth
        respuesta_auth = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

        usuario = respuesta_auth.user
        sesion  = respuesta_auth.session

        if not usuario:
            return {"status": "error", "message": "Credenciales inválidas"}

        # Paso 2: Obtener perfil de la tabla pública 'perfiles'
        resultado_perfil = (
            supabase.table("perfiles")
            .select("*")
            .eq("user_id", usuario.id)
            .single()
            .execute()
        )

        return {
            "status": "ok",
            "access_token": sesion.access_token,  # 🔗 Flutter: guarda en SharedPreferences
            "token_type": "bearer",
            "usuario": {
                "id":    usuario.id,
                "email": usuario.email,
            },
            "perfil": resultado_perfil.data   # rol, nombre, foto, provincia, etc.
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}
    
