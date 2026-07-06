"""
preferencias_router.py
Traducción de screens/preferencias.py (borrador) → FastAPI activo
Guarda las provincias, comarcas y categorías de interés del comprador
(pantalla "Cuéntanos tus intereses" tras registro/login/invitado).
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import List
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/preferencias", tags=["Preferencias"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class PreferenciasUpdate(BaseModel):
    user_id: str
    provincias: List[str] = []
    comarcas: List[str] = []
    categorias: List[str] = []

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/{user_id}")
def obtener_preferencias_usuario(user_id: str):
    """
    Obtiene las provincias, comarcas y categorías de interés guardadas por el usuario.
    🔗 FLUTTER: GET /preferencias/{user_id}
    """
    try:
        resp = (
            supabase.table("user_preferences")
            .select("provincias, comarcas, categorias")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        if not resp or not resp.data:
            return {"provincias": [], "comarcas": [], "categorias": []}

        data = resp.data
        return {
            "provincias": data.get("provincias") or [],
            "comarcas": data.get("comarcas") or [],
            "categorias": data.get("categorias") or [],
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener las preferencias: {str(e)}",
        )


@router.post("/guardar", status_code=status.HTTP_200_OK)
def guardar_preferencias_usuario(data: PreferenciasUpdate):
    """
    Guarda o actualiza (upsert) las provincias, comarcas y categorías seleccionadas.
    🔗 FLUTTER: POST /preferencias/guardar
    """
    try:
        payload = {
            "user_id": data.user_id,
            "provincias": data.provincias,
            "comarcas": data.comarcas,
            "categorias": data.categorias,
        }
        resp = (
            supabase.table("user_preferences")
            .upsert(payload, on_conflict="user_id")
            .execute()
        )
        return {"success": True, "data": resp.data}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar las preferencias en la base de datos: {str(e)}",
        )
