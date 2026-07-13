"""
chat_router.py
Chat 1:1 entre comprador/vendedor/proveedor: conversaciones persistentes
con mensajes de texto, imagen y publicaciones compartidas.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/chat", tags=["Chat"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class AbrirConversacionRequest(BaseModel):
    usuario_id: str = Field(..., min_length=1)
    usuario_nombre: str = Field(..., min_length=1)
    contacto_id: Optional[str] = None
    contacto_nombre: str = Field(..., min_length=1)
    contacto_rol: str = "Cliente"


class EnviarMensajeRequest(BaseModel):
    conversacion_id: str
    autor_id: str = Field(..., min_length=1)
    autor_nombre: str = Field(..., min_length=1)
    contenido: str = Field(..., min_length=1)
    tipo: str = "texto"  # "texto" | "imagen" | "publicacion"
    publicacion_id: Optional[str] = None


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

def _otro_participante(conv: dict, user_id: str) -> dict:
    """Devuelve nombre/id/rol del OTRO participante visto desde user_id."""
    if conv.get("participante_1_id") == user_id:
        return {
            "id": conv.get("participante_2_id"),
            "nombre": conv.get("participante_2_nombre"),
            "rol": conv.get("participante_2_rol") or "Cliente",
        }
    return {
        "id": conv.get("participante_1_id"),
        "nombre": conv.get("participante_1_nombre"),
        "rol": "Cliente",
    }


def _serializar_conversacion(conv: dict, user_id: str, no_leidos: int = 0, foto_contacto: str = "") -> dict:
    otro = _otro_participante(conv, user_id)
    return {
        "id": str(conv.get("id", "")),
        "nombre_contacto": otro["nombre"] or "Usuario CraftHub",
        "id_contacto": otro["id"],
        "rol_contacto": otro["rol"],
        "foto_contacto": foto_contacto,
        "ultimo_mensaje": conv.get("ultimo_mensaje") or "",
        "ultimo_mensaje_hora": conv.get("ultimo_mensaje_hora"),
        "mensajes_no_leidos": no_leidos,
    }


def _fotos_de_perfiles(ids: list) -> dict:
    """Busca en un solo query la foto de perfil de cada user_id dado."""
    ids_validos = [i for i in ids if i]
    if not ids_validos:
        return {}
    try:
        resp = (
            supabase.table("perfiles")
            .select("user_id, foto")
            .in_("user_id", ids_validos)
            .execute()
        )
        return {p["user_id"]: (p.get("foto") or "") for p in (resp.data or [])}
    except Exception:
        return {}


def _serializar_mensaje(m: dict, para_usuario_id: str) -> dict:
    return {
        "id": str(m.get("id", "")),
        "conversacion_id": str(m.get("conversacion_id", "")),
        "contenido": m.get("contenido") or "",
        "tipo": m.get("tipo") or "texto",
        "publicacion_id": m.get("publicacion_id"),
        "es_mio": m.get("autor_id") == para_usuario_id,
        "autor_nombre": m.get("autor_nombre"),
        "hora": m.get("created_at"),
        "leido": bool(m.get("leido") or False),
    }


# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/conversaciones/{user_id}")
def listar_conversaciones(user_id: str):
    """
    Lista las conversaciones de un usuario (comprador o vendedor), más
    recientes primero, con el conteo de mensajes sin leer de cada una.
    🔗 FLUTTER: GET /api/chat/conversaciones/{userId}
    """
    try:
        resp = (
            supabase.table("conversaciones")
            .select("*")
            .or_(f"participante_1_id.eq.{user_id},participante_2_id.eq.{user_id}")
            .order("ultimo_mensaje_hora", desc=True)
            .execute()
        )
        conversaciones = resp.data or []
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando conversaciones: {ex}")

    fotos = _fotos_de_perfiles(
        [_otro_participante(conv, user_id).get("id") for conv in conversaciones]
    )

    resultado = []
    for conv in conversaciones:
        try:
            no_leidos_resp = (
                supabase.table("mensajes")
                .select("id", count="exact")
                .eq("conversacion_id", conv["id"])
                .eq("leido", False)
                .neq("autor_id", user_id)
                .execute()
            )
            no_leidos = no_leidos_resp.count or 0
        except Exception:
            no_leidos = 0
        foto = fotos.get(_otro_participante(conv, user_id).get("id"), "")
        resultado.append(_serializar_conversacion(conv, user_id, no_leidos, foto))

    return {"conversaciones": resultado, "total": len(resultado)}


@router.post("/conversaciones/abrir")
def abrir_conversacion(req: AbrirConversacionRequest):
    """
    Busca una conversación existente entre usuario_id y el contacto (por id
    si lo tiene, o por nombre si el contacto no tiene cuenta todavía, p. ej.
    un proveedor); si no existe, la crea.
    🔗 FLUTTER: POST /api/chat/conversaciones/abrir
    """
    try:
        propias = (
            supabase.table("conversaciones")
            .select("*")
            .or_(f"participante_1_id.eq.{req.usuario_id},participante_2_id.eq.{req.usuario_id}")
            .execute()
            .data
            or []
        )

        for conv in propias:
            otro = _otro_participante(conv, req.usuario_id)
            coincide = (
                (req.contacto_id and otro.get("id") == req.contacto_id)
                or (not otro.get("id") and (otro.get("nombre") or "").strip().lower() == req.contacto_nombre.strip().lower())
            )
            if coincide:
                foto = _fotos_de_perfiles([otro.get("id")]).get(otro.get("id"), "")
                return {"conversacion": _serializar_conversacion(conv, req.usuario_id, 0, foto)}

        nueva = {
            "participante_1_id": req.usuario_id,
            "participante_1_nombre": req.usuario_nombre,
            "participante_2_id": req.contacto_id,
            "participante_2_nombre": req.contacto_nombre,
            "participante_2_rol": req.contacto_rol,
            "ultimo_mensaje": "",
        }
        resultado = supabase.table("conversaciones").insert(nueva).execute()
        if not resultado.data:
            raise HTTPException(status_code=400, detail="No se pudo crear la conversación.")
        foto = _fotos_de_perfiles([req.contacto_id]).get(req.contacto_id, "")
        return {"conversacion": _serializar_conversacion(resultado.data[0], req.usuario_id, 0, foto)}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error abriendo la conversación: {ex}")


@router.get("/mensajes/{conversacion_id}")
def listar_mensajes(conversacion_id: str, para_usuario_id: str):
    """
    Lista los mensajes de una conversación en orden cronológico.
    🔗 FLUTTER: GET /api/chat/mensajes/{conversacionId}?para_usuario_id=...
    """
    try:
        resp = (
            supabase.table("mensajes")
            .select("*")
            .eq("conversacion_id", conversacion_id)
            .order("created_at")
            .execute()
        )
        mensajes = [_serializar_mensaje(m, para_usuario_id) for m in (resp.data or [])]
        return {"mensajes": mensajes, "total": len(mensajes)}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando mensajes: {ex}")


@router.post("/mensajes")
def enviar_mensaje(req: EnviarMensajeRequest):
    """
    Envía un mensaje y actualiza el resumen (último mensaje/hora) de la
    conversación.
    🔗 FLUTTER: POST /api/chat/mensajes
    """
    try:
        nuevo = {
            "conversacion_id": req.conversacion_id,
            "autor_id": req.autor_id,
            "autor_nombre": req.autor_nombre,
            "contenido": req.contenido,
            "tipo": req.tipo,
            "publicacion_id": req.publicacion_id,
            "leido": False,
        }
        resultado = supabase.table("mensajes").insert(nuevo).execute()
        if not resultado.data:
            raise HTTPException(status_code=400, detail="No se pudo enviar el mensaje.")

        resumen = req.contenido if req.tipo == "texto" else (
            "📷 Imagen" if req.tipo == "imagen" else "🔗 Publicación compartida"
        )
        supabase.table("conversaciones").update({
            "ultimo_mensaje": resumen,
            "ultimo_mensaje_hora": resultado.data[0]["created_at"],
        }).eq("id", req.conversacion_id).execute()

        return {"mensaje": _serializar_mensaje(resultado.data[0], req.autor_id)}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error enviando el mensaje: {ex}")


@router.delete("/conversaciones/{conversacion_id}")
def eliminar_conversacion(conversacion_id: str):
    """
    Elimina una conversación y sus mensajes (los mensajes se borran en
    cascada por la FK conversacion_id).
    🔗 FLUTTER: DELETE /api/chat/conversaciones/{conversacionId}
    """
    try:
        supabase.table("conversaciones").delete().eq("id", conversacion_id).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error eliminando la conversación: {ex}")


@router.patch("/mensajes/{conversacion_id}/leidos")
def marcar_mensajes_leidos(conversacion_id: str, usuario_id: str):
    """
    Marca como leídos todos los mensajes de la conversación que NO fueron
    escritos por usuario_id (o sea, los del otro participante).
    🔗 FLUTTER: PATCH /api/chat/mensajes/{conversacionId}/leidos?usuario_id=...
    """
    try:
        supabase.table("mensajes").update({"leido": True}).eq(
            "conversacion_id", conversacion_id
        ).eq("leido", False).neq("autor_id", usuario_id).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error marcando mensajes como leídos: {ex}")
