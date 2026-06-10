"""
notificaciones_router.py
Traducción de screens/notificaciones.py (Flet) → FastAPI
"""

from fastapi import APIRouter, HTTPException
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/notificaciones", tags=["Notificaciones"])

# ---------------------------------------------------------------------------
# CONSTANTES
# ---------------------------------------------------------------------------
ESTADOS = ["pendiente", "en proceso", "enviado", "entregado"]

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
def _precio(valor) -> float:
    try:
        if isinstance(valor, (int, float)):
            return float(valor)
        return float(str(valor).replace("$", "").replace(",", ""))
    except Exception:
        return 0.0

def _estado_normal(valor) -> str:
    texto = (valor or "pendiente").strip().lower()
    if texto in ["preparando", "proceso", "procesando"]:
        return "en proceso"
    if texto in ["camino", "en camino"]:
        return "enviado"
    if texto not in ESTADOS:
        return "pendiente"
    return texto

def _paso_indice(estado) -> int:
    e = _estado_normal(estado)
    if e in ("pendiente", "en proceso"):
        return 0
    if e == "enviado":
        return 2
    return 3

def _mensaje_comprador(estado) -> str:
    return {
        "pendiente":  "Tu pedido fue recibido",
        "en proceso": "Tu pedido se esta preparando",
        "enviado":    "Tu pedido esta en camino",
        "entregado":  "Tu pedido fue entregado",
    }.get(_estado_normal(estado), "Tu pedido fue recibido")

def _mensaje_vendedor(estado) -> str:
    return {
        "pendiente":  "Nueva venta",
        "en proceso": "Pedido en preparacion",
        "enviado":    "Pedido enviado",
        "entregado":  "Venta completada",
    }.get(_estado_normal(estado), "Nueva venta")

def _fecha_corta(valor) -> str:
    return (valor or "")[:10] or "Ahora"

def _items_de_vendedor(pedido, nombres_productos):
    nombres = set(nombres_productos)
    return [item for item in (pedido.get("productos") or []) if item.get("nombre") in nombres]

def _serializar_item_comprador(pedido, item) -> dict:
    estado = _estado_normal(item.get("estado") or pedido.get("estado"))
    cantidad = int(item.get("cantidad", 1) or 1)
    precio = _precio(item.get("precio", 0))
    nombre = item.get("nombre", "Producto")
    return {
        "pedido_id":        pedido.get("id"),
        "comprador_nombre": pedido.get("comprador_nombre"),
        "total":            pedido.get("total"),
        "metodo_pago":      pedido.get("metodo_pago"),
        "fecha":            _fecha_corta(pedido.get("created_at")),
        "item": {
            "nombre":      nombre,
            "img":         item.get("img") or item.get("imagen") or "",
            "cantidad":    cantidad,
            "precio":      precio,
            "subtotal":    round(precio * cantidad, 2),
            "estado":      estado,
            "mensaje":     _mensaje_comprador(estado),
            "paso_indice": _paso_indice(estado),
            "pasos":       ["Preparando", "Enviado", "En camino", "Entregado"],
        },
    }

def _serializar_item_vendedor(pedido, item, leida=False) -> dict:
    estado = _estado_normal(item.get("estado") or pedido.get("estado"))
    cantidad = int(item.get("cantidad", 1) or 1)
    precio = _precio(item.get("precio", 0))
    nombre = item.get("nombre", "Producto")
    return {
        "pedido_id":        pedido.get("id"),
        "comprador_nombre": pedido.get("comprador_nombre") or "Cliente",
        "total":            pedido.get("total"),
        "fecha":            _fecha_corta(pedido.get("created_at")),
        "leida":            leida,
        "item": {
            "nombre":           nombre,
            "img":              item.get("img") or item.get("imagen") or "",
            "cantidad":         cantidad,
            "precio":           precio,
            "subtotal":         round(precio * cantidad, 2),
            "estado":           estado,
            "mensaje_vendedor": _mensaje_vendedor(estado),
            "paso_indice":      _paso_indice(estado),
            "pasos":            ["Preparando", "Enviado", "En camino", "Entregado"],
            "pago_aprobado":    True,
        },
    }

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/comprador/{comprador_id}")
def notificaciones_comprador(comprador_id: str):
    """
    Pedidos del comprador con estado por producto y barra de progreso.
    🔗 FLUTTER: GET /api/notificaciones/comprador/{comprador_id}
    """
    try:
        pedidos = (
            supabase.table("pedidos")
            .select("*")
            .eq("comprador_id", comprador_id)
            .order("created_at", desc=True)
            .execute()
            .data or []
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))

    cards = []
    for pedido in pedidos:
        for item in (pedido.get("productos") or []):
            cards.append(_serializar_item_comprador(pedido, item))

    return {"total": len(cards), "notificaciones": cards}


@router.get("/vendedor/{nombre_vendedor}")
def notificaciones_vendedor(nombre_vendedor: str):
    """
    Pedidos que contienen productos del vendedor.
    🔗 FLUTTER: GET /api/notificaciones/vendedor/{nombre_vendedor}
    """
    try:
        nombres_prods = [
            p.get("nombre")
            for p in (
                supabase.table("productos")
                .select("nombre")
                .eq("creador", nombre_vendedor)
                .execute()
                .data or []
            )
        ]
        todos = (
            supabase.table("pedidos")
            .select("*")
            .order("created_at", desc=True)
            .execute()
            .data or []
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))

    pedidos_vendedor = [p for p in todos if _items_de_vendedor(p, nombres_prods)]

    cards = []
    for pedido in pedidos_vendedor:
        for item in _items_de_vendedor(pedido, nombres_prods):
            cards.append(_serializar_item_vendedor(pedido, item))

    return {"total": len(cards), "notificaciones": cards}


@router.patch("/{notificacion_id}/leida")
def marcar_leida(notificacion_id: str):
    """
    Marca una notificación como leída.
    🔗 FLUTTER: PATCH /api/notificaciones/{notificacion_id}/leida
    """
    try:
        supabase.table("notificaciones").update({"leida": True}).eq("id", notificacion_id).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))
