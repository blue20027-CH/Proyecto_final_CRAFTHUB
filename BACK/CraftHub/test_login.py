import sys
import os

# Asegurar rutas locales
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

def probar_autenticacion(email, password):
    print(f"\n--- Intentando conectar con: {email} ---")
    try:
        # Paso 1: Autenticar correo y contraseña en Supabase Auth
        r = supabase.auth.sign_in_with_password({
            'email': email,
            'password': password
        })
        print("¡Login Exitoso en Supabase Auth!")
        print("User ID:", r.user.id)

        # Paso 2: Buscar el perfil asociado en tu base de datos publica
        perfil = supabase.table("perfiles").select("*").eq("user_id", r.user.id).single().execute()
        print("Datos del Perfil encontrado:", perfil.data)
        
        return {"user": r.user, "perfil": perfil.data}

    except Exception as e:
        print("¡ERROR EN LA AUTENTICACIÓN! Detalles:", e)
        return None

if __name__ == "__main__":
    # Puedes cambiar estos datos por cualquier cuenta real creada en tu Supabase
    correo_prueba = "benitobarsallo7@gmail.com"
    clave_prueba = "benito12"
    
    probar_autenticacion(correo_prueba, clave_prueba)