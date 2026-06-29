"""
perfil_router.py
Traducción de screens/menu_perfil.py (Flet) → FastAPI
"""

from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional
import sys, os, uuid
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/perfil", tags=["Perfil"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class CerrarSesionRequest(BaseModel):
    user_id: str

class ActualizarPerfilRequest(BaseModel):
    foto_portada: Optional[str] = None
    foto:         Optional[str] = None
    descripcion:  Optional[str] = None
    ubicacion:    Optional[str] = None
    telefono:     Optional[str] = None

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
            "nombre":       nombre,
            "email":        perfil.get("email") or "craft@crafthub.com",
            "foto":         perfil.get("foto") or perfil.get("ft") or "",
            "foto_portada": perfil.get("foto_portada") or "",
            "iniciales":    iniciales,
            "ubicacion":    perfil.get("ubicacion") or "",
            "telefono":     perfil.get("telefono") or "",
            "modo":         perfil.get("modo") or "comprador",
        }
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.patch("/{user_id}")
def actualizar_perfil(user_id: str, req: ActualizarPerfilRequest):
    """
    Actualiza campos del perfil del usuario.
    🔗 FLUTTER: PATCH /api/perfil/{user_id}
    Body: { "foto_portada": "url", "foto": "url", "descripcion": "...", etc. }
    """
    try:
        datos = {k: v for k, v in req.dict().items() if v is not None}
        if not datos:
            raise HTTPException(status_code=400, detail="No hay datos para actualizar.")
        supabase.table("perfiles").update(datos).eq("user_id", user_id).execute()
        return {"success": True}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.post("/{user_id}/subir-foto")
async def subir_foto_perfil(user_id: str, file: UploadFile = File(...), tipo: str = "foto"):
    """
    Sube una foto al Storage de Supabase y actualiza el perfil.
    tipo = 'foto' → actualiza campo foto
    tipo = 'portada' → actualiza campo foto_portada
    🔗 FLUTTER: POST /api/perfil/{user_id}/subir-foto?tipo=portada
    """
    try:
        contenido = await file.read()
        extension = file.filename.split(".")[-1] if file.filename else "jpg"
        nombre_archivo = f"perfil_{user_id}_{uuid.uuid4().hex[:8]}.{extension}"
        bucket = "perfiles"
        path = f"{user_id}/{nombre_archivo}"

        supabase.storage.from_(bucket).upload(
            path, contenido, {"content-type": file.content_type or "image/jpeg"}
        )
        url = supabase.storage.from_(bucket).get_public_url(path)

        campo = "foto_portada" if tipo == "portada" else "foto"
        supabase.table("perfiles").update({campo: url}).eq("user_id", user_id).execute()

        return {"success": True, "url": url, "campo": campo}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.get("/menu/{user_id}")
def menu_perfil(user_id: str):
    """
    Devuelve las opciones del menú lateral según el modo del usuario.
    🔗 FLUTTER: GET /api/perfil/menu/{user_id}
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
    """
    try:
        supabase.auth.sign_out()
        return {"success": True, "mensaje": "Sesión cerrada correctamente."}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))