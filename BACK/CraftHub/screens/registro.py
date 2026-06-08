from fastapi import FastAPI, HTTPException, status
from supabase_client import supabase  # Tu cliente instanciado de Supabase
from schemas import RegistroUsuario

app = FastAPI(title="CraftHub Auth API", version="1.0")

@app.post("/auth/register", status_code=status.HTTP_201_CREATED)
def registrar_usuario(datos: RegistroUsuario):
    """
    Registra un usuario en Supabase Auth y crea su perfil correspondiente 
    en la tabla 'perfiles'.
    """
    try:
        # 1. Crear el usuario en el módulo de Autenticación de Supabase
        response = supabase.auth.sign_up({
            "email": datos.email,
            "password": datos.password,
        })
        
        user = response.user
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail="No se pudo crear la cuenta de autenticación. Intenta de nuevo."
            )

        # 2. Insertar la información complementaria en la tabla 'perfiles'
        perfil_data = {
            "user_id": user.id,
            "nombre": datos.nombre.strip(),
            "telefono": datos.telefono.strip() if datos.telefono else None,
            "ubicacion": datos.ubicacion.strip() if datos.ubicacion else None,
            "rol": datos.rol,
        }
        
        supabase.table("perfiles").insert(perfil_data).execute()

        # 3. Retornar la respuesta de éxito junto con los datos procesados
        return {
            "status": "success",
            "message": "Usuario registrado exitosamente.",
            "usuario": {
                "id": user.id,
                "email": user.email,
                "perfil": {
                    "nombre": perfil_data["nombre"],
                    "rol": perfil_data["rol"],
                    "telefono": perfil_data["telefono"],
                    "ubicacion": perfil_data["ubicacion"]
                }
            }
        }

    except Exception as ex:
        msg = str(ex)
        # Mapeo de errores idéntico al que tenías en el frontend
        if "already registered" in msg or "already been registered" in msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este correo ya tiene una cuenta activa. Inicia sesión."
            )
        elif "invalid" in msg.lower() and "email" in msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El formato del correo electrónico no es válido."
            )
        
        # Cualquier otro error inesperado de Supabase o conexión
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en el servidor: {msg}"
        )