"""
eventos_router.py
Endpoints para la pantalla de calendario de eventos artesanales
(comprador/vendedor). Usa las tablas creadas por sql/eventos_schema.sql.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from supabase_client import supabase

router = APIRouter(prefix="/api/eventos", tags=["Eventos"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class OrganizadorPayload(BaseModel):
    nombre: str
    tipo: Optional[str] = "Vendedor organizador"
    telefono: Optional[str] = ""
    whatsapp: Optional[str] = ""
    email: Optional[str] = ""
    sitio_web: Optional[str] = ""
    foto_url: Optional[str] = ""


class EventoCreate(BaseModel):
    titulo: str
    descripcion: Optional[str] = ""
    categoria: str = "Feria"
    imagen_url: Optional[str] = ""
    fecha_inicio: str
    fecha_fin: str
    ubicacion: str
    provincia: str
    latitud: Optional[float] = 8.9824
    longitud: Optional[float] = -79.5199
    es_gratuito: bool = True
    precio_entrada: Optional[float] = 0
    cupos_vendedor_total: Optional[int] = 0
    cupos_vendedor_disponibles: Optional[int] = 0
    descuento_porcentaje: Optional[int] = None
    descuento_desde: Optional[str] = None
    descuento_hasta: Optional[str] = None
    organizador: OrganizadorPayload


class SolicitudVendedorRequest(BaseModel):
    vendedor_id: str
    mensaje: Optional[str] = ""


class FavoritoEventoRequest(BaseModel):
    user_id: str
    es_favorito: bool


_SELECT_CON_ORGANIZADOR = "*, organizador:organizadores_eventos(*)"


# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("")
def obtener_eventos(
    categoria: Optional[str] = None,
    provincia: Optional[str] = None,
    busqueda: Optional[str] = None,
):
    """
    Lista los eventos con su organizador embebido.
    🔗 FLUTTER: GET /api/eventos?categoria=&provincia=&busqueda=
    """
    try:
        query = supabase.table("eventos").select(_SELECT_CON_ORGANIZADOR)
        if categoria and categoria != "Todos":
            query = query.eq("categoria", categoria)
        if provincia:
            query = query.eq("provincia", provincia)
        eventos = query.order("fecha_inicio").execute().data or []

        if busqueda:
            b = busqueda.lower()
            eventos = [
                e for e in eventos if
                b in (e.get("titulo") or "").lower() or
                b in (e.get("ubicacion") or "").lower() or
                b in (e.get("provincia") or "").lower()
            ]
        return {"eventos": eventos}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar eventos: {str(e)}")


@router.post("")
def crear_evento(req: EventoCreate):
    """
    Crea un evento. Si el organizador (por nombre) no existe todavía en
    organizadores_eventos, lo crea de una vez.
    🔗 FLUTTER: POST /api/eventos
    """
    try:
        existente = supabase.table("organizadores_eventos") \
            .select("id").eq("nombre", req.organizador.nombre).execute().data

        if existente:
            organizador_id = existente[0]["id"]
        else:
            nuevo_organizador = supabase.table("organizadores_eventos").insert({
                "nombre": req.organizador.nombre,
                "tipo": req.organizador.tipo,
                "telefono": req.organizador.telefono,
                "whatsapp": req.organizador.whatsapp,
                "email": req.organizador.email,
                "sitio_web": req.organizador.sitio_web,
                "foto_url": req.organizador.foto_url,
            }).execute()
            organizador_id = nuevo_organizador.data[0]["id"]

        creado = supabase.table("eventos").insert({
            "titulo": req.titulo,
            "descripcion": req.descripcion,
            "categoria": req.categoria,
            "imagen_url": req.imagen_url,
            "fecha_inicio": req.fecha_inicio,
            "fecha_fin": req.fecha_fin,
            "ubicacion": req.ubicacion,
            "provincia": req.provincia,
            "latitud": req.latitud,
            "longitud": req.longitud,
            "es_gratuito": req.es_gratuito,
            "precio_entrada": req.precio_entrada,
            "cupos_vendedor_total": req.cupos_vendedor_total,
            "cupos_vendedor_disponibles": req.cupos_vendedor_disponibles,
            "descuento_porcentaje": req.descuento_porcentaje,
            "descuento_desde": req.descuento_desde,
            "descuento_hasta": req.descuento_hasta,
            "organizador_id": organizador_id,
        }).execute()

        nuevo_id = creado.data[0]["id"]
        resultado = supabase.table("eventos") \
            .select(_SELECT_CON_ORGANIZADOR).eq("id", nuevo_id).execute().data
        return resultado[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear evento: {str(e)}")


@router.post("/{evento_id}/solicitudes-vendedor")
def solicitar_espacio_vendedor(evento_id: int, req: SolicitudVendedorRequest):
    """
    Registra la solicitud de un vendedor para participar en el evento; el
    organizador recibe sus datos de contacto para coordinar directamente.
    🔗 FLUTTER: POST /api/eventos/{evento_id}/solicitudes-vendedor
    """
    try:
        evento = supabase.table("eventos").select("id").eq("id", evento_id).execute().data
        if not evento:
            raise HTTPException(status_code=404, detail="Evento no encontrado")

        resultado = supabase.table("eventos_solicitudes_vendedor").insert({
            "evento_id": evento_id,
            "vendedor_id": req.vendedor_id,
            "mensaje": req.mensaje,
        }).execute()
        return {
            "ok": True,
            "mensaje": "Solicitud enviada al organizador.",
            "solicitud": resultado.data[0],
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al enviar la solicitud: {str(e)}")


@router.post("/{evento_id}/favorito")
def alternar_favorito(evento_id: int, req: FavoritoEventoRequest):
    """
    Marca/desmarca un evento como favorito para un comprador.
    🔗 FLUTTER: POST /api/eventos/{evento_id}/favorito
    """
    try:
        if req.es_favorito:
            existe = supabase.table("eventos_favoritos") \
                .select("id").eq("user_id", req.user_id).eq("evento_id", evento_id).execute().data
            if not existe:
                supabase.table("eventos_favoritos").insert({
                    "user_id": req.user_id,
                    "evento_id": evento_id,
                }).execute()
        else:
            supabase.table("eventos_favoritos") \
                .delete().eq("user_id", req.user_id).eq("evento_id", evento_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar favorito: {str(e)}")


@router.get("/favoritos/{user_id}", response_model=None)
def obtener_favoritos_usuario(user_id: str) -> dict:
    """
    Lista los eventos favoritos de un comprador (con organizador embebido).
    🔗 FLUTTER: GET /api/eventos/favoritos/{user_id}
    """
    try:
        favs = supabase.table("eventos_favoritos").select("evento_id").eq("user_id", user_id).execute().data or []
        ids: List[int] = [f["evento_id"] for f in favs]
        if not ids:
            return {"eventos": []}
        eventos = supabase.table("eventos").select(_SELECT_CON_ORGANIZADOR).in_("id", ids).execute().data or []
        return {"eventos": eventos}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar favoritos: {str(e)}")
