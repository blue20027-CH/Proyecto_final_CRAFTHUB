"""
anuncios_router.py
Mensajes que CraftHub (la plataforma) manda a todos los usuarios a la vez,
con seguimiento de "no leído" por usuario para el puntito rojo del chat.
"""

from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/anuncios", tags=["Anuncios CraftHub"])


class AnuncioCreate(BaseModel):
    texto: str
    titulo: Optional[str] = "CraftHub"


@router.post("/", status_code=status.HTTP_201_CREATED)
def crear_anuncio(data: AnuncioCreate):
    """
    Crea un anuncio que le llega a TODOS los usuarios (comprador y vendedor).
    🔗 Uso: POST /anuncios  Body: { "texto": "...", "titulo": "CraftHub" }
    """
    if not data.texto.strip():
        raise HTTPException(status_code=400, detail="El mensaje no puede estar vacío.")
    try:
        resp = supabase.table("anuncios").insert({
            "titulo": (data.titulo or "CraftHub").strip(),
            "texto": data.texto.strip(),
        }).execute()
        return {"success": True, "data": resp.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el anuncio: {str(e)}")


@router.get("/{user_id}")
def obtener_anuncios(user_id: str):
    """
    Lista los anuncios de CraftHub y cuántos no ha visto este usuario aún.
    🔗 FLUTTER: GET /anuncios/{user_id}
    """
    try:
        anuncios = supabase.table("anuncios").select("*").order("created_at", desc=True).execute().data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar anuncios: {str(e)}")

    try:
        visto_resp = supabase.table("anuncios_leidos").select("ultima_vista").eq("user_id", user_id).maybe_single().execute()
        ultima_vista = (visto_resp.data or {}).get("ultima_vista") if visto_resp else None
    except Exception:
        ultima_vista = None

    if not anuncios:
        no_leidos = 0
    elif not ultima_vista:
        no_leidos = len(anuncios)
    else:
        no_leidos = sum(1 for a in anuncios if (a.get("created_at") or "") > ultima_vista)

    return {"anuncios": anuncios, "no_leidos": no_leidos}


@router.post("/marcar-leido")
def marcar_leido(data: dict):
    """
    Marca todos los anuncios como leídos para este usuario (apaga el puntito rojo).
    🔗 FLUTTER: POST /anuncios/marcar-leido  Body: { "user_id": "..." }
    """
    user_id = (data.get("user_id") or "").strip()
    if not user_id:
        raise HTTPException(status_code=400, detail="Falta user_id.")
    try:
        supabase.table("anuncios_leidos").upsert({
            "user_id": user_id,
            "ultima_vista": datetime.now(timezone.utc).isoformat(),
        }, on_conflict="user_id").execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al marcar como leído: {str(e)}")
