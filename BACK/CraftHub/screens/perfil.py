from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import Optional
from supabase_client import supabase  # Tu cliente de Supabase configurado

router = APIRouter(
    prefix="/perfil",
    tags=["Perfil de Usuario"]
)

# ─── SCHEMAS DE REQUERIMIENTOS (PYDANTIC) ───────────────────────────

class PerfilUpdate(BaseModel):
    nombre: str = Field(..., min_length=1, description="El nombre completo no puede estar vacío")
    telefono: Optional[str] = ""
    ubicacion: Optional[str] = ""

class PerfilResponse(BaseModel):
    user_id: str
    nombre: str
    telefono: Optional[str] = None
    ubicacion: Optional[str] = None
    rol: str
    created_at: str


# ─── ENDPOINTS DE PERFIL ────────────────────────────────────────────

@router.get("/{user_id}", response_model=PerfilResponse)
def obtener_perfil(user_id: str):
    """
    Recupera los datos del perfil de un usuario específico desde Supabase.
    """
    try:
        resp = supabase.table("perfiles")\
            .select("user_id, nombre, telefono, ubicacion, rol, created_at")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()
        
        if not resp.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El perfil solicitado no existe."
            )
            
        return resp.data
        
    except HTTPException as http_ex:
        raise http_ex
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener el perfil: {str(e)}"
        )


@router.put("/{user_id}", status_code=status.HTTP_200_OK)
def actualizar_perfil(user_id: str, datos: PerfilUpdate):
    """
    Actualiza la información modificable del perfil (nombre, teléfono, ubicación).
    El rol y la fecha de creación quedan protegidos en el backend.
    """
    # Validación manual extra en caso de strings compuestos solo por espacios
    if not datos.nombre.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre completo no puede consistir únicamente en espacios vacíos."
        )

    try:
        payload = {
            "nombre": datos.nombre.strip(),
            "telefono": datos.telefono.strip() if datos.telefono else "",
            "ubicacion": datos.ubicacion.strip() if datos.ubicacion else ""
        }

        # Actualización dirigida por user_id
        resp = supabase.table("perfiles")\
            .update(payload)\
            .eq("user_id", user_id)\
            .execute()

        if not resp.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No se encontró el perfil para actualizar."
            )

        return {
            "status": "success",
            "message": "Perfil actualizado correctamente.",
            "data": resp.data[0]
        }

    except HTTPException as http_ex:
        raise http_ex
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar el perfil en la base de datos: {str(e)}"
        )