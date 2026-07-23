import uuid
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel

from supabase_client import supabase

router = APIRouter(prefix="/api/tutoriales", tags=["Tutoriales"])

# Límite de tamaño para videos subidos directamente (protege la cuota gratis
# de Supabase Storage, que en el plan free ronda los 50 MB por archivo).
MAX_VIDEO_MB = 50


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
    Todos los tutoriales publicados (oficiales de CraftHub y los subidos por
    artesanos), más recientes primero.
    🔗 FLUTTER: GET /api/tutoriales?categoria=X
    """
    try:
        query = supabase.table("tutoriales").select("*")
        if categoria and categoria.lower() not in ("todas", "all"):
            # Case-insensitive: "Joyería" en el chip matchea aunque la fila
            # esté guardada como "joyería" o "JOYERIA".
            query = query.ilike("categoria", categoria)

        data = query.order("created_at", desc=True).execute().data or []

        creador_ids = list({t["creador_id"] for t in data if t.get("creador_id")})
        perfiles_por_id = {}
        if creador_ids:
            perfiles = (
                supabase.table("perfiles")
                .select("user_id, nombre, foto")
                .in_("user_id", creador_ids)
                .execute()
                .data or []
            )
            perfiles_por_id = {p["user_id"]: p for p in perfiles}

        tutoriales = []
        for t in data:
            perfil = perfiles_por_id.get(t.get("creador_id"))
            nombre = (perfil or {}).get("nombre") or "CraftHub"
            foto = (perfil or {}).get("foto") or ""
            tutoriales.append(_tutorial_a_dict(t, nombre, foto))
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


@router.get("/{tutorial_id}")
def obtener_tutorial(tutorial_id: str):
    """
    Detalle de un tutorial puntual (para la pantalla de reproducción).
    🔗 FLUTTER: GET /api/tutoriales/{id}
    """
    try:
        data = supabase.table("tutoriales").select("*").eq("id", tutorial_id).execute().data
        if not data:
            raise HTTPException(status_code=404, detail="Tutorial no encontrado")
        t = data[0]
        nombre_artesano, foto_artesano = "CraftHub", ""
        if t.get("creador_id"):
            perfil = (
                supabase.table("perfiles")
                .select("nombre, foto")
                .eq("user_id", t["creador_id"])
                .execute()
                .data
            )
            if perfil:
                nombre_artesano = perfil[0].get("nombre") or "CraftHub"
                foto_artesano = perfil[0].get("foto") or ""
        return _tutorial_a_dict(t, nombre_artesano, foto_artesano)
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando tutorial: {ex}")


@router.post("/{tutorial_id}/vista")
def registrar_vista(tutorial_id: str):
    """
    Suma 1 a las vistas del tutorial. Se llama una vez cada vez que un
    comprador/vendedor abre la pantalla de detalle del video.
    🔗 FLUTTER: POST /api/tutoriales/{id}/vista
    """
    try:
        actual = (
            supabase.table("tutoriales")
            .select("vistas")
            .eq("id", tutorial_id)
            .execute()
            .data
        )
        if not actual:
            raise HTTPException(status_code=404, detail="Tutorial no encontrado")
        nuevas_vistas = (actual[0].get("vistas") or 0) + 1
        supabase.table("tutoriales").update({"vistas": nuevas_vistas}).eq(
            "id", tutorial_id
        ).execute()
        return {"status": "ok", "vistas": nuevas_vistas}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error registrando vista: {ex}")


@router.post("/subir-video")
async def subir_video(file: UploadFile = File(...)):
    """
    Sube un archivo de video al Storage de Supabase y devuelve su URL pública,
    para tutoriales que el artesano graba y sube directamente (sin YouTube).
    🔗 FLUTTER: POST /api/tutoriales/subir-video (multipart, campo "file")
    """
    try:
        contenido = await file.read()
        if len(contenido) > MAX_VIDEO_MB * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail=f"El video supera el límite de {MAX_VIDEO_MB} MB. Comprímelo o súbelo a YouTube y pega el enlace.",
            )
        extension = (file.filename.split(".")[-1] if file.filename else "mp4").lower()
        nombre_archivo = f"tutorial_video_{uuid.uuid4().hex[:12]}.{extension}"
        bucket = "productos"  # bucket público existente; reutilizado para videos
        supabase.storage.from_(bucket).upload(
            nombre_archivo, contenido, {"content-type": file.content_type or "video/mp4"}
        )
        url = supabase.storage.from_(bucket).get_public_url(nombre_archivo)
        return {"success": True, "url": url}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error al subir el video: {str(ex)}")


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