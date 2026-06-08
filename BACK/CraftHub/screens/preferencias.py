from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import List, Optional
from supabase_client import supabase  # Tu cliente de Supabase configurado

router = APIRouter(
    prefix="/preferencias",
    tags=["Preferencias de Usuario"]
)

# ─── SCHEMAS DE REQUERIMIENTOS (PYDANTIC) ───────────────────────────

class PreferenciasUpdate(BaseModel):
    user_id: str
    provincias: List[str]
    categorias: List[str]


# ─── ENDPOINTS DE PREFERENCIAS ──────────────────────────────────────

@router.get("/{user_id}")
def obtener_preferencias_usuario(user_id: str):
    """
    Obtiene las provincias y categorías de interés guardadas por el usuario.
    """
    try:
        # Consultamos la tabla de perfiles o preferencias del usuario
        resp = supabase.table("user_preferences")\
            .select("provincias, categorias")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()
        
        # Si el usuario es nuevo y no tiene registros todavía
        if not resp.data:
            return {"provincias": [], "categorias": []}
            
        return resp.data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener las preferencias: {str(e)}"
        )


@router.post("/guardar", status_code=status.HTTP_200_OK)
def guardar_preferencias_usuario(data: PreferenciasUpdate):
    """
    Guarda o actualiza (Upsert) las provincias y categorías seleccionadas por el usuario.
    """
    # Validación de reglas de negocio (ej. mínimo 3 si no es omitible en el frontend)
    # Nota: Si dejas 'omitible=True', puedes remover o condicionar esta validación de longitud.
    if len(data.provincias) < 3 or len(data.categorias) < 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debes seleccionar al menos 3 provincias y 3 categorías de interés."
        )

    try:
        preferencias_payload = {
            "user_id": data.user_id,
            "provincias": data.provincias,  # Almacenados como tipo Array / JSONB en Supabase
            "categorias": data.categorias,  # Almacenados como tipo Array / JSONB en Supabase
        }

        # Utilizamos upsert para insertar o actualizar basándonos en la clave primaria (user_id)
        resp = supabase.table("user_preferences")\
            .upsert(preferencias_payload, on_conflict="user_id")\
            .execute()

        return {
            "status": "success",
            "message": "Preferencias sincronizadas correctamente",
            "data": resp.data
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar las preferencias en la base de datos: {str(e)}"
        )