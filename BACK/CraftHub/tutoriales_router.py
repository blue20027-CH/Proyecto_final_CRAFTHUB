from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from supabase_client import supabase

router = APIRouter(prefix="/api/tutoriales", tags=["Tutoriales"])


def _id_youtube(url: str) -> str:
    if not url:
        return ""
    if "youtu.be/" in url:
        return url.split("youtu.be/")[-1].split("?")[0]
    if "watch?v=" in url:
        return url.split("watch?v=")[-1].split("&")[0]
    return ""


def _publicado_hace(fecha_iso: Optional[str]) -> str:
    if not fecha_iso:
        return ""
    try:
        fecha = datetime.fromisoformat(fecha_iso.replace("Z", "+00:00"))
        ahora = datetime.now(timezone.utc)
        dias = (ahora - fecha).days
        if dias <= 0:
            return "Hoy"
        if dias == 1:
            return "Hace 1 día"
        if dias < 7:
            return f"Hace {dias} días"
        if dias < 30:
            semanas = dias // 7
            return f"Hace {semanas} semana{'s' if semanas > 1 else ''}"
        meses = dias // 30
        return f"Hace {meses} mes{'es' if meses > 1 else ''}"
    except Exception:
        return ""


def _tutorial_a_dict(t: dict, nombre_artesano: str = "CraftHub", foto_artesano: str = "") -> dict:
    video_id = _id_youtube(t.get("youtube_url") or "")
    thumbnail = t.get("thumbnail_url") or (
        f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg" if video_id else ""
    )
    return {
        "id": str(t.get("id", "")),
        "titulo": t.get("titulo") or "Tutorial",
        "descripcion": t.get("descripcion") or "",
        "youtube_url": t.get("youtube_url") or "",
        "miniatura": thumbnail,
        "categoria": t.get("categoria") or "General",
        "duracion": t.get("duracion") or "",
        "vistas": t.get("vistas") or 0,
        "creador_id": t.get("creador_id"),
        "nombre_artesano": nombre_artesano,
        "avatar_artesano": foto_artesano,
        "publicado_hace": _publicado_hace(t.get("created_at")),
    }


@router.get("")
def listar_tutoriales(categoria: Optional[str] = None):
    """
    Tutoriales oficiales de CraftHub (creador_id es NULL).
    🔗 FLUTTER: GET /api/tutoriales?categoria=X
    """
    try:
        query = supabase.table("tutoriales").select("*")
        if categoria and categoria.lower() not in ("todas", "all"):
            query = query.eq("categoria", categoria)

        data = query.execute().data or []
        print(f"[tutoriales] Total en BD: {len(data)}")
        data_oficiales = [t for t in data if t.get("creador_id") is None]
        print(f"[tutoriales] Oficiales (creador_id=NULL): {len(data_oficiales)}")
        tutoriales = [_tutorial_a_dict(t, "CraftHub", "") for t in data_oficiales]
        return {"tutoriales": tutoriales}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando tutoriales: {ex}")


@router.get("/mis-videos")
def mis_videos(creador_id: str):
    """
    Videos subidos por un vendedor específico.
    🔗 FLUTTER: GET /api/tutoriales/mis-videos?creador_id=UUID
    """
    try:
        data = (
            supabase.table("tutoriales")
            .select("*")
            .eq("creador_id", creador_id)
            .execute()
            .data or []
        )
        perfil = (
            supabase.table("perfiles")
            .select("nombre, foto")
            .eq("user_id", creador_id)
            .execute()
            .data
        )
        nombre = perfil[0]["nombre"] if perfil else "Yo"
        foto = (perfil[0].get("foto") or "") if perfil else ""
        tutoriales = [_tutorial_a_dict(t, nombre, foto) for t in data]
        return {"tutoriales": tutoriales}
    except Exception as ex:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error cargando mis videos: {repr(ex)}")


class TutorialNuevo(BaseModel):
    titulo: str
    descripcion: Optional[str] = None
    youtube_url: str
    categoria: Optional[str] = "General"
    duracion: Optional[str] = None
    creador_id: str


@router.post("")
def crear_tutorial(payload: TutorialNuevo):
    """
    Sube un nuevo tutorial del vendedor.
    🔗 FLUTTER: POST /api/tutoriales
    """
    try:
        nuevo = {
            "titulo": payload.titulo,
            "descripcion": payload.descripcion,
            "youtube_url": payload.youtube_url,
            "categoria": payload.categoria,
            "duracion": payload.duracion,
            "creador_id": payload.creador_id,
            "vistas": 0,
        }
        resultado = supabase.table("tutoriales").insert(nuevo).execute()
        return {"status": "ok", "tutorial": resultado.data[0] if resultado.data else nuevo}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error creando tutorial: {ex}")


@router.delete("/{tutorial_id}")
def eliminar_tutorial(tutorial_id: str):
    """
    Elimina un tutorial.
    🔗 FLUTTER: DELETE /api/tutoriales/{id}
    """
    try:
        supabase.table("tutoriales").delete().eq("id", tutorial_id).execute()
        return {"status": "ok"}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error eliminando tutorial: {ex}")