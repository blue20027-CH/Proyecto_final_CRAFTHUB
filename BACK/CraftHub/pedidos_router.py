"""
pedidos_router.py
Traducción de screens/pago.py + screens/notificaciones.py (Flet) → FastAPI
"""

import math
from typing import Optional, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/pagos", tags=["Pagos"])

# ---------------------------------------------------------------------------
# CONSTANTES DE ENVÍO
# ---------------------------------------------------------------------------
COORDENADAS = {
    "Panama":        (8.9936, -79.5197),
    "Colon":         (9.3564, -79.9006),
    "David":         (8.4003, -82.4322),
    "Santiago":      (8.0997, -80.9833),
    "Chitre":        (7.9667, -80.4333),
    "Penonome":      (8.5167, -80.3500),
    "La Palma":      (8.4000, -78.1333),
    "Bocas del Toro":(9.3333, -82.2500),
    "Changuinola":   (9.4333, -82.5167),
}
PRECIO_POR_KM   = 0.05
COSTO_MINIMO    = 1.50
COSTO_MAXIMO    = 15.00

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------
class ProductoCarrito(BaseModel):
    id:        Optional[str]   = None
    nombre:    str
    precio:    float
    cantidad:  int             = 1
    creador:   Optional[str]   = None
    img:       Optional[str]   = None
    categoria: Optional[str]   = None

class DatosTarjeta(BaseModel):
    nombre_tarjeta: str
    numero:         str   # Solo se guardan los últimos 4
    vence:          str
    cvv:            str   # No se persiste

class DatosTransferencia(BaseModel):
    banco:      str
    titular:    str
    cuenta:     str
    referencia: Optional[str] = None

class DatosBilletera(BaseModel):
    billetera: str   # "Yappy" | "PayPal" | "Banistmo"
    contacto:  str   # Teléfono o correo

class PedidoRequest(BaseModel):
    comprador_id:      Optional[str] = None
    comprador_nombre:  str
    ubicacion_comprador: str         = "Panama"
    telefono:          Optional[str] = None
    carrito:           List[ProductoCarrito]
    metodo_pago:       str           # "Tarjeta" | "Transferencia" | "Yappy" | "PayPal" | "Banistmo"
    datos_tarjeta:     Optional[DatosTarjeta]      = None
    datos_transferencia: Optional[DatosTransferencia] = None
    datos_billetera:   Optional[DatosBilletera]    = None

# ---------------------------------------------------------------------------
# HELPERS DE ENVÍO  (equivalente a screens/envio.py)
# ---------------------------------------------------------------------------
def _haversine(lat1, lon1, lat2, lon2) -> float:
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))

def _get_coords(ubicacion: str):
    for key, coords in COORDENADAS.items():
        if key.lower() in (ubicacion or "").lower():
            return coords
    return COORDENADAS["Panama"]

def _ubicacion_vendedor(nombre: str) -> Optional[str]:
    try:
        resp = supabase.table("perfiles").select("ubicacion").eq("nombre", nombre).execute()
        if resp.data:
            return resp.data[0].get("ubicacion")
    except Exception as ex:
        print(f"Error buscando ubicación del vendedor {nombre}:", ex)
    return None

def _calcular_envio(carrito: List[ProductoCarrito], ubicacion_comprador: str):
    coord_comprador = _get_coords(ubicacion_comprador)
    envio_total = 0.0
    detalle = []
    procesados = set()

    for item in carrito:
        creador = item.creador
        if not creador or creador in procesados:
            continue
        procesados.add(creador)

        ubi_vendedor = _ubicacion_vendedor(creador)
        coord_vendedor = _get_coords(ubi_vendedor or "Panama")

        distancia = _haversine(*coord_vendedor, *coord_comprador)
        costo = max(COSTO_MINIMO, min(COSTO_MAXIMO, distancia * PRECIO_POR_KM))

        envio_total += costo
        detalle.append({
            "vendedor":     creador,
            "distancia_km": round(distancia, 1),
            "costo":        round(costo, 2),
        })

    return round(envio_total, 2), detalle

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.post("/resumen")
def resumen_pedido(carrito: List[ProductoCarrito], ubicacion_comprador: str = "Panama"):
    """
    Calcula subtotal, envío y total antes de confirmar el pago.
    🔗 FLUTTER: POST /api/pagos/resumen
    """
    subtotal = sum(p.precio * p.cantidad for p in carrito)
    envio, detalle_envio = _calcular_envio(carrito, ubicacion_comprador) if subtotal > 0 else (0.0, [])
    return {
        "subtotal":      round(subtotal, 2),
        "envio":         envio,
        "total":         round(subtotal + envio, 2),
        "detalle_envio": detalle_envio,
    }


@router.post("/crear")
def crear_pedido(req: PedidoRequest):
    """
    Crea el pedido, descuenta stock y notifica a los vendedores.
    🔗 FLUTTER: POST /api/pagos/crear
    """
    if not req.carrito:
        raise HTTPException(status_code=400, detail="El carrito está vacío.")

    # Validar datos según método
    if req.metodo_pago == "Tarjeta" and not req.datos_tarjeta:
        raise HTTPException(status_code=400, detail="Faltan datos de la tarjeta.")
    if req.metodo_pago == "Transferencia" and not req.datos_transferencia:
        raise HTTPException(status_code=400, detail="Faltan datos de la transferencia.")
    if req.metodo_pago in ("Yappy", "PayPal", "Banistmo") and not req.datos_billetera:
        raise HTTPException(status_code=400, detail="Faltan datos de la billetera.")

    # Calcular montos
    subtotal = sum(p.precio * p.cantidad for p in req.carrito)
    envio, detalle_envio = _calcular_envio(req.carrito, req.ubicacion_comprador)
    total = round(subtotal + envio, 2)

    # Armar datos_pago según método
    if req.metodo_pago == "Tarjeta":
        datos_pago = {
            "nombre_tarjeta": req.datos_tarjeta.nombre_tarjeta,
            "ultimos_4":      req.datos_tarjeta.numero[-4:],
            "vence":          req.datos_tarjeta.vence,
        }
    elif req.metodo_pago == "Transferencia":
        datos_pago = {
            "banco":      req.datos_transferencia.banco,
            "titular":    req.datos_transferencia.titular,
            "cuenta":     req.datos_transferencia.cuenta,
            "referencia": req.datos_transferencia.referencia,
        }
    else:  # Billetera
        datos_pago = {
            "billetera": req.datos_billetera.billetera,
            "contacto":  req.datos_billetera.contacto,
        }

    datos_pago.update({
        "subtotal":      subtotal,
        "envio":         envio,
        "detalle_envio": detalle_envio,
    })

    # Lista de productos
    productos_lista = [
        {
            "id":       p.id,
            "nombre":   p.nombre,
            "precio":   p.precio,
            "cantidad": p.cantidad,
            "creador":  p.creador,
            "img":      p.img,
            "categoria":p.categoria,
            "estado":   "pendiente",
        }
        for p in req.carrito
    ]

    # Insertar pedido
    try:
        result = supabase.table("pedidos").insert({
            "comprador_id":     req.comprador_id,
            "comprador_nombre": req.comprador_nombre,
            "productos":        productos_lista,
            "total":            total,
            "metodo_pago":      req.metodo_pago,
            "estado":           "pendiente",
            "direccion":        req.ubicacion_comprador,
            "telefono":         req.telefono,
            "datos_pago":       datos_pago,
        }).execute()
        pedido_id = result.data[0]["id"] if result.data else None
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error guardando el pedido: {ex}")

    # Descontar stock
    for item in productos_lista:
        try:
            resp = supabase.table("productos").select("id, stock").eq("nombre", item["nombre"]).execute()
            if resp.data:
                prod = resp.data[0]
                nuevo_stock = max(0, int(prod.get("stock", 0) or 0) - item["cantidad"])
                supabase.table("productos").update({"stock": nuevo_stock}).eq("id", prod["id"]).execute()
        except Exception as ex:
            print(f"Error actualizando stock de {item['nombre']}:", ex)

    # Notificar vendedores
    notificados = set()
    for item in productos_lista:
        creador = item.get("creador")
        if not creador or creador in notificados:
            continue
        try:
            resp = supabase.table("perfiles").select("user_id").eq("nombre", creador).execute()
            if resp.data:
                comprador = req.comprador_nombre or "Un cliente"
                supabase.table("notificaciones").insert({
                    "user_id": resp.data[0].get("user_id"),
                    "titulo":  "Nueva venta",
                    "mensaje": f"{comprador} compró {item['cantidad']}x {item['nombre']}. Preparalo para enviarlo antes de 24 horas.",
                    "tipo":    "venta",
                    "leida":   False,
                }).execute()
                notificados.add(creador)
        except Exception as ex:
            print(f"Error enviando notificación a {creador}:", ex)

    return {
        "success":    True,
        "pedido_id":  pedido_id,
        "total":      total,
        "metodo_pago": req.metodo_pago,
        "mensaje":    "Pedido creado exitosamente.",
    }


@router.get("/metodos")
def metodos_pago():
    """
    Lista de métodos de pago disponibles para renderizar en Flutter.
    🔗 FLUTTER: GET /api/pagos/metodos
    """
    return {
        "metodos": [
            {
                "id":       "Tarjeta",
                "titulo":   "Tarjeta de débito o Crédito",
                "subtitulo":"Visa, Mastercard, American Express",
                "icono":    "credit-card",
            },
            {
                "id":       "Transferencia",
                "titulo":   "Transferencia Bancaria",
                "subtitulo":"Realiza tu pago desde tu banco",
                "icono":    "building-bank",
                "bancos":   ["Banistmo", "Banco Nacional", "BAC Credomatic", "Global Bank", "Caja de Ahorros"],
            },
            {"id": "Yappy",    "titulo": "Yappy",    "icono": "wallet", "campo": "telefono"},
            {"id": "PayPal",   "titulo": "PayPal",   "icono": "wallet", "campo": "correo"},
            {"id": "Banistmo", "titulo": "Banistmo", "icono": "wallet", "campo": "telefono"},
        ]
    }


@router.get("/historial/{comprador_id}")
def historial_pedidos(comprador_id: str):
    """
    Historial de pedidos de un comprador.
    🔗 FLUTTER: GET /api/pagos/historial/{comprador_id}
    """
    try:
        resp = supabase.table("pedidos").select("*").eq("comprador_id", comprador_id).execute()
        return {"pedidos": resp.data}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


# ---------------------------------------------------------------------------
# HELPERS DE NOTIFICACIONES  (equivalente a screens/notificaciones.py)
# ---------------------------------------------------------------------------
ESTADOS = ["pendiente", "en proceso", "enviado", "entregado", "cancelado"]

def _estado_normal(valor: str) -> str:
    texto = (valor or "pendiente").strip().lower()
    if texto in ["preparando", "proceso", "procesando", "aceptada", "aceptado"]:
        return "en proceso"
    if texto in ["camino", "en camino"]:
        return "enviado"
    if texto in ["cancelada", "cancelado", "cancelar"]:
        return "cancelado"
    if texto in ["completada", "completado"]:
        return "entregado"
    if texto not in ESTADOS:
        return "pendiente"
    return texto

def _paso_indice(estado: str) -> int:
    e = _estado_normal(estado)
    if e == "cancelado":
        return -1
    if e in ("pendiente", "en proceso"):
        return 0
    if e == "enviado":
        return 2
    return 3  # entregado

def _mensaje_comprador(estado: str) -> str:
    e = _estado_normal(estado)
    mensajes = {
        "pendiente":  "Tu pedido fue recibido",
        "en proceso": "Tu pedido se está preparando",
        "enviado":    "Tu pedido está en camino",
        "entregado":  "Tu pedido fue entregado",
        "cancelado":  "Tu pedido fue cancelado",
    }
    return mensajes.get(e, "Tu pedido fue recibido")

def _mensaje_vendedor(estado: str) -> str:
    e = _estado_normal(estado)
    mensajes = {
        "pendiente":  "Nueva venta",
        "en proceso": "Pedido en preparación",
        "enviado":    "Pedido enviado",
        "entregado":  "Venta completada",
        "cancelado":  "Pedido cancelado",
    }
    return mensajes.get(e, "Nueva venta")

def _precio_float(valor) -> float:
    try:
        if isinstance(valor, (int, float)):
            return float(valor)
        return float(str(valor).replace("$", "").replace(",", ""))
    except Exception:
        return 0.0

def _serializar_item(pedido: dict, item: dict) -> dict:
    estado = _estado_normal(item.get("estado") or pedido.get("estado"))
    cantidad = int(item.get("cantidad", 1) or 1)
    precio = _precio_float(item.get("precio", 0))
    return {
        "nombre":        item.get("nombre", "Producto"),
        "img":           item.get("img") or item.get("imagen") or "",
        "cantidad":      cantidad,
        "precio":        precio,
        "subtotal":      round(precio * cantidad, 2),
        "creador":       item.get("creador"),
        "categoria":     item.get("categoria"),
        "estado":        estado,
        "mensaje":       _mensaje_comprador(estado),
        "paso_indice":   _paso_indice(estado),
        "pasos":         ["Preparando", "Enviado", "En camino", "Entregado"],
    }

def _serializar_pedido_base(pedido: dict) -> dict:
    return {
        "id":                pedido.get("id"),
        "comprador_nombre":  pedido.get("comprador_nombre"),
        "total":             pedido.get("total"),
        "metodo_pago":       pedido.get("metodo_pago"),
        "estado":            _estado_normal(pedido.get("estado")),
        "direccion":         pedido.get("direccion"),
        "telefono":          pedido.get("telefono"),
        "created_at":        (pedido.get("created_at") or "")[:10] or "Ahora",
    }

# ---------------------------------------------------------------------------
# ENDPOINTS DE NOTIFICACIONES
# ---------------------------------------------------------------------------

@router.get("/notificaciones/comprador/{comprador_id}")
def notificaciones_comprador(comprador_id: str):
    """
    Notificaciones del comprador: todos sus pedidos con estado por producto.
    🔗 FLUTTER: GET /api/pagos/notificaciones/comprador/{comprador_id}
    Respuesta: lista de cards con info de seguimiento por item.
    """
    try:
        resp = (
            supabase.table("pedidos")
            .select("*")
            .eq("comprador_id", comprador_id)
            .order("created_at", desc=True)
            .execute()
        )
        pedidos = resp.data or []
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))

    cards = []
    for pedido in pedidos:
        base = _serializar_pedido_base(pedido)
        for item in (pedido.get("productos") or []):
            cards.append({
                **base,
                "item": _serializar_item(pedido, item),
            })

    return {"total": len(cards), "notificaciones": cards}


@router.get("/notificaciones/vendedor/{nombre_vendedor}")
def notificaciones_vendedor(nombre_vendedor: str):
    """
    Notificaciones del vendedor: pedidos que contienen productos suyos.
    🔗 FLUTTER: GET /api/pagos/notificaciones/vendedor/{nombre_vendedor}
    Respuesta: lista de cards con info del pedido + item vendido.
    """
    try:
        prods_resp = (
            supabase.table("productos")
            .select("nombre")
            .eq("creador", nombre_vendedor)
            .execute()
        )
        nombres_prods = {p.get("nombre") for p in (prods_resp.data or [])}

        todos = (
            supabase.table("pedidos")
            .select("*")
            .order("created_at", desc=True)
            .execute()
            .data or []
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))

    cards = []
    for pedido in todos:
        items_vendedor = [
            item for item in (pedido.get("productos") or [])
            if item.get("nombre") in nombres_prods
        ]
        if not items_vendedor:
            continue

        base = _serializar_pedido_base(pedido)
        for item in items_vendedor:
            estado = _estado_normal(item.get("estado") or pedido.get("estado"))
            cantidad = int(item.get("cantidad", 1) or 1)
            precio = _precio_float(item.get("precio", 0))
            cards.append({
                **base,
                "item": {
                    "nombre":            item.get("nombre", "Producto"),
                    "img":               item.get("img") or item.get("imagen") or "",
                    "cantidad":          cantidad,
                    "precio":            precio,
                    "subtotal":          round(precio * cantidad, 2),
                    "estado":            estado,
                    "mensaje_vendedor":  _mensaje_vendedor(estado),
                    "paso_indice":       _paso_indice(estado),
                    "pasos":             ["Preparando", "Enviado", "En camino", "Entregado"],
                    "pago_aprobado":     True,
                },
            })

    return {"total": len(cards), "notificaciones": cards}


@router.patch("/notificaciones/{notificacion_id}/leida")
def marcar_leida(notificacion_id: str):
    """
    Marca una notificación como leída.
    🔗 FLUTTER: PATCH /api/pagos/notificaciones/{notificacion_id}/leida
    """
    try:
        supabase.table("notificaciones").update({"leida": True}).eq("id", notificacion_id).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))