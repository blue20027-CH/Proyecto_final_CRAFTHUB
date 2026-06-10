"""
perfil_router.py
Traducción de screens/menu_perfil.py (Flet) → FastAPI
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/perfil", tags=["Perfil"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class CerrarSesionRequest(BaseModel):
    user_id: str

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/{user_id}")
def obtener_perfil(user_id: str):
    """
    Devuelve el perfil del usuario con los datos del menú lateral.
    🔗 FLUTTER: GET /api/perfil/{user_id}
    """
    try:
        resp = supabase.table("perfiles").select("*").eq("user_id", user_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Perfil no encontrado.")
        perfil = resp.data[0]
        nombre = perfil.get("nombre") or "Usuario CraftHub"
        iniciales = "".join([p[0].upper() for p in nombre.split()[:2]]) or "CH"
        return {
            "nombre":    nombre,
            "email":     perfil.get("email") or "craft@crafthub.com",
            "foto":      perfil.get("foto") or "",
            "iniciales": iniciales,
            "ubicacion": perfil.get("ubicacion") or "",
            "telefono":  perfil.get("telefono") or "",
            "modo":      perfil.get("modo") or "comprador",  # "comprador" | "vendedor"
        }
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.get("/menu/{user_id}")
def menu_perfil(user_id: str):
    """
    Devuelve las opciones del menú lateral según el modo del usuario.
    🔗 FLUTTER: GET /api/perfil/menu/{user_id}
    Respuesta: lista de opciones con icono, texto y ruta para Flutter.
    """
    try:
        resp = supabase.table("perfiles").select("nombre, foto, email, modo").eq("user_id", user_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Perfil no encontrado.")
        perfil = resp.data[0]
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))

    nombre = perfil.get("nombre") or "Usuario CraftHub"
    modo = perfil.get("modo") or "comprador"
    iniciales = "".join([p[0].upper() for p in nombre.split()[:2]]) or "CH"

    if modo == "vendedor":
        opciones = [
            {"icono": "building-store", "texto": "Mis productos", "ruta": "mis_productos",  "activo": False},
            {"icono": "plus",           "texto": "Crear",         "ruta": "crear",           "activo": True},
            {"icono": "chart-bar",      "texto": "Estudio",       "ruta": "estudio",         "activo": False},
            {"icono": "receipt",        "texto": "Pedidos",       "ruta": "pedidos",         "activo": False},
            {"icono": "user",           "texto": "Clientes",      "ruta": "clientes",        "activo": False},
        ]
    else:
        opciones = [
            {"icono": "user",          "texto": "Mi perfil", "ruta": "perfil",   "activo": False},
            {"icono": "search",        "texto": "Explorar",  "ruta": "explorar", "activo": True},
            {"icono": "shopping-cart", "texto": "Carrito",   "ruta": "carrito",  "activo": False},
            {"icono": "receipt",       "texto": "Pedidos",   "ruta": "pedidos",  "activo": False},
        ]

    return {
        "nombre":    nombre,
        "email":     perfil.get("email") or "craft@crafthub.com",
        "foto":      perfil.get("foto") or "",
        "iniciales": iniciales,
        "modo":      modo,
        "opciones":  opciones,
    }


@router.post("/cerrar-sesion")
def cerrar_sesion(req: CerrarSesionRequest):
    """
    Cierra la sesión del usuario en Supabase.
    🔗 FLUTTER: POST /api/perfil/cerrar-sesion
    En Flutter maneja el logout local adicionalmente (limpiar SharedPreferences, etc.)
    """
    try:
        supabase.auth.sign_out()
        return {"success": True, "mensaje": "Sesión cerrada correctamente."}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))
