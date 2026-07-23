import math
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from supabase_client import supabase
from pedidos_router import _estado_normal, _get_coords

router = APIRouter(prefix="/api/vendedor", tags=["Vendedor"])

# ---------------------------------------------------------------------------
# ESTADOS DE PEDIDO (vocabulario del vendedor) ↔ ESTADOS CANÓNICOS (BD)
# ---------------------------------------------------------------------------
ESTADO_VENDEDOR_A_CANONICO = {
    "pendiente":  "pendiente",
    "aceptada":   "en proceso",
    "aceptado":   "en proceso",
    "en proceso": "en proceso",
    "enviado":    "enviado",
    "en camino":  "enviado",
    "completada": "entregado",
    "completado": "entregado",
    "entregado":  "entregado",
    "cancelada":  "cancelado",
    "cancelado":  "cancelado",
}

ESTADOS_CANONICOS_VALIDOS = {"pendiente", "en proceso", "enviado", "entregado", "cancelado"}


def _canonizar_estado_vendedor(estado: str) -> str:
    return ESTADO_VENDEDOR_A_CANONICO.get((estado or "").strip().lower(), "pendiente")


def _vendedor_estado_label(estado: str) -> str:
    """Etiqueta mostrada en la tabla de órdenes del vendedor."""
    return {
        "pendiente":  "Pendiente",
        "en proceso": "Aceptada",
        "enviado":    "Enviado",
        "entregado":  "Completada",
        "cancelado":  "Cancelada",
    }.get(estado, "Pendiente")


def _mapa_estado_label(estado: str) -> str:
    """Etiqueta mostrada en los pines del mapa del vendedor."""
    return {
        "pendiente":  "Pendiente",
        "en proceso": "Aceptada",
        "enviado":    "En camino",
        "entregado":  "Entregado",
        "cancelado":  "Cancelado",
    }.get(estado, "Pendiente")


def _formato_orden_id(pedido_id) -> str:
    texto = str(pedido_id)
    if texto.isdigit():
        return f"#CH-{int(texto):06d}"
    return f"#CH-{texto.replace('-', '')[:6].upper()}"


def _comentarios_de_vendedor(productos: list) -> list:
    """Todos los comentarios (con calificación o no) de los productos del vendedor."""
    ids = [p.get("id") for p in productos if p.get("id") is not None]
    if not ids:
        return []
    try:
        resp = (
            supabase.table("comentarios")
            .select("*")
            .in_("producto_id", ids)
            .order("created_at", desc=True)
            .execute()
        )
        return resp.data or []
    except Exception:
        return []


def _precio_float(valor) -> float:
    try:
        return float(str(valor or 0).replace("$", "").replace(",", ""))
    except Exception:
        return 0.0


def _cantidad_int(valor) -> int:
    try:
        return int(valor or 0)
    except Exception:
        return 0


def _producto_para_inventario(producto: dict, ventas: int = 0) -> dict:
    stock = _cantidad_int(producto.get("stock"))
    estado = producto.get("estado")
    if not estado:
        estado = "agotado" if stock <= 0 else "activo"

    return {
        "id": str(producto.get("id", "")),
        "sku": producto.get("sku") or f"PROD-{producto.get('id', '')}",
        "nombre": producto.get("nombre") or "Producto",
        "coleccion": producto.get("coleccion") or producto.get("origen") or "General",
        "categoria": producto.get("categoria") or "General",
        "precio": _precio_float(producto.get("precio")),
        "stock": stock,
        "ventas": ventas,
        "estado": estado,
        "imagen_url": producto.get("imagen_url") or producto.get("imagen") or producto.get("img") or "",
        "descripcion": producto.get("descripcion") or "",
        "tallas": producto.get("tallas") or "",
    }


def _productos_y_ventas(nombre_vendedor: str):
    productos = (
        supabase.table("productos")
        .select("*")
        .eq("creador", nombre_vendedor)
        .execute()
        .data
        or []
    )
    nombres = {p.get("nombre") for p in productos if p.get("nombre")}

    pedidos = supabase.table("pedidos").select("*").execute().data or []
    ventas_por_producto = defaultdict(int)
    ingresos_por_producto = defaultdict(float)
    pedidos_vendedor = set()
    pendientes = 0
    ingresos_total = 0.0

    for pedido in pedidos:
        pedido_tiene_item = False
        for item in pedido.get("productos") or []:
            if item.get("nombre") not in nombres:
                continue

            cantidad = _cantidad_int(item.get("cantidad") or 1)
            precio = _precio_float(item.get("precio"))
            subtotal = round(precio * cantidad, 2)
            estado = (item.get("estado") or pedido.get("estado") or "pendiente").lower()

            ventas_por_producto[item.get("nombre")] += cantidad
            ingresos_por_producto[item.get("nombre")] += subtotal
            ingresos_total += subtotal
            pedido_tiene_item = True

            if estado in {"pendiente", "en proceso", "preparando", "procesando"}:
                pendientes += 1

        if pedido_tiene_item:
            pedidos_vendedor.add(str(pedido.get("id")))

    return productos, ventas_por_producto, ingresos_por_producto, len(pedidos_vendedor), pendientes, ingresos_total


_MESES_ES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
             "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]


def _ingresos_mensuales(nombre_vendedor: str, meses: int = 6):
    """
    Ingresos reales del vendedor mes por mes, para los últimos `meses` meses
    (terminando en el mes actual), usando la fecha de cada pedido. Devuelve
    (valores, etiquetas, variacion_pct) donde la variación compara el último
    mes contra el anterior.
    """
    productos = (
        supabase.table("productos")
        .select("nombre")
        .eq("creador", nombre_vendedor)
        .execute()
        .data
        or []
    )
    nombres = {p.get("nombre") for p in productos if p.get("nombre")}

    ahora = datetime.now(timezone.utc)
    # Construye las cubetas (año, mes) de los últimos `meses` meses en orden.
    cubetas = []
    y, m = ahora.year, ahora.month
    for _ in range(meses):
        cubetas.append((y, m))
        m -= 1
        if m == 0:
            m = 12
            y -= 1
    cubetas.reverse()
    indice = {ym: i for i, ym in enumerate(cubetas)}
    valores = [0.0] * meses

    pedidos = supabase.table("pedidos").select("productos, total, created_at").execute().data or []
    for pedido in pedidos:
        creado = pedido.get("created_at")
        if not creado:
            continue
        try:
            fecha = datetime.fromisoformat(str(creado).replace("Z", "+00:00"))
        except Exception:
            continue
        pos = indice.get((fecha.year, fecha.month))
        if pos is None:
            continue
        for item in pedido.get("productos") or []:
            if item.get("nombre") not in nombres:
                continue
            valores[pos] += _precio_float(item.get("precio")) * _cantidad_int(item.get("cantidad") or 1)

    valores = [round(v, 2) for v in valores]
    etiquetas = [_MESES_ES[ym[1] - 1] for ym in cubetas]

    variacion = 0
    if meses >= 2 and valores[-2] > 0:
        variacion = round((valores[-1] - valores[-2]) / valores[-2] * 100)
    elif valores[-1] > 0 and (meses < 2 or valores[-2] == 0):
        variacion = 100

    return valores, etiquetas, variacion


@router.get("/{nombre_vendedor}/productos")
def productos_vendedor(nombre_vendedor: str, q: Optional[str] = None):
    try:
        productos, ventas, _, _, _, ingresos_total = _productos_y_ventas(nombre_vendedor)
        data = [_producto_para_inventario(p, ventas[p.get("nombre")]) for p in productos]

        if q:
            texto = q.lower()
            data = [
                p for p in data
                if texto in p["nombre"].lower()
                or texto in p["sku"].lower()
                or texto in p["categoria"].lower()
            ]

        estadisticas = {
            "total": len(data),
            "activos": sum(1 for p in data if p["estado"] == "activo"),
            "agotados": sum(1 for p in data if p["estado"] == "agotado"),
            "visitas_mes": 0,
            "ventas_totales": round(ingresos_total, 2),
        }
        return {"productos": data, "estadisticas": estadisticas}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando productos del vendedor: {ex}")


@router.get("/{nombre_vendedor}/dashboard")
def dashboard_vendedor(nombre_vendedor: str, periodo: Optional[str] = None):
    try:
        productos, ventas, ingresos, pedidos_totales, pendientes, ingresos_total = _productos_y_ventas(nombre_vendedor)

        ingresos_mensuales, etiquetas_meses, variacion_ingresos = _ingresos_mensuales(nombre_vendedor)

        ranking = sorted(
            productos,
            key=lambda p: ventas[p.get("nombre")],
            reverse=True,
        )[:5]

        top_productos = [
            {
                "posicion": i + 1,
                "nombre": p.get("nombre") or "Producto",
                "categoria": p.get("categoria") or "General",
                "imagen_url": p.get("imagen_url") or p.get("imagen") or p.get("img") or "",
                "ventas": ventas[p.get("nombre")],
                "ingresos": round(ingresos[p.get("nombre")], 2),
            }
            for i, p in enumerate(ranking)
        ]

        productos_activos = sum(1 for p in productos if _cantidad_int(p.get("stock")) > 0)

        # ── Evaluaciones reales (tabla `comentarios` de los productos del vendedor) ──
        comentarios = _comentarios_de_vendedor(productos)
        calificaciones = [c["calificacion"] for c in comentarios if c.get("calificacion") is not None]
        promedio_evaluacion = round(sum(calificaciones) / len(calificaciones), 1) if calificaciones else 0
        total_evaluaciones = len(calificaciones)
        distribucion_evaluaciones = {"5": 0, "4": 0, "3": 0, "2": 0, "1": 0}
        for cal in calificaciones:
            estrella = str(min(5, max(1, round(cal))))
            distribucion_evaluaciones[estrella] = distribucion_evaluaciones.get(estrella, 0) + 1

        # "Nuevas opiniones" = comentarios publicados en los últimos 30 días
        ahora = datetime.now(timezone.utc)
        nuevas_opiniones = 0
        for c in comentarios:
            creado = c.get("created_at")
            if not creado:
                continue
            try:
                fecha = datetime.fromisoformat(str(creado).replace("Z", "+00:00"))
                if (ahora - fecha).days <= 30:
                    nuevas_opiniones += 1
            except Exception:
                continue

        # ── Visitas reales al perfil (tabla `visitas_perfil`) ──
        try:
            visitas_resp = (
                supabase.table("visitas_perfil")
                .select("id", count="exact")
                .eq("vendedor_nombre", nombre_vendedor)
                .execute()
            )
            visitas_perfil = visitas_resp.count or 0
        except Exception:
            visitas_perfil = 0

        return {
            "nombre_vendedor": nombre_vendedor,
            "ingresos_total": round(ingresos_total, 2),
            "variacion_ingresos": variacion_ingresos,
            "ingresos_mensuales": ingresos_mensuales,
            "etiquetas_meses": etiquetas_meses,
            "top_productos": top_productos,
            "promedio_evaluacion": promedio_evaluacion,
            "total_evaluaciones": total_evaluaciones,
            "distribucion_evaluaciones": distribucion_evaluaciones,
            "clientes_felices": pedidos_totales,
            "nuevas_opiniones": nuevas_opiniones,
            "pedidos_totales": pedidos_totales,
            "pendientes_enviar": pendientes,
            "productos_activos": productos_activos,
            "visitas_tienda": visitas_perfil,
        }
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando dashboard del vendedor: {ex}")


@router.get("/{nombre_vendedor}/opiniones")
def opiniones_vendedor(nombre_vendedor: str, limite: int = 20):
    """
    Opiniones (comentarios) recientes sobre los productos del vendedor.
    🔗 FLUTTER: GET /api/vendedor/{nombre}/opiniones
    """
    try:
        productos, *_ = _productos_y_ventas(nombre_vendedor)
        comentarios = _comentarios_de_vendedor(productos)[:limite]
        nombres_productos = {p.get("id"): (p.get("nombre") or "Producto") for p in productos}
        return {
            "opiniones": [
                {
                    "id": c.get("id"),
                    "producto": nombres_productos.get(c.get("producto_id"), "Producto"),
                    "nombre": c.get("nombre") or "Comprador CraftHub",
                    "comentario": c.get("comentario"),
                    "calificacion": c.get("calificacion"),
                    "avatar_url": c.get("avatar_url"),
                    "created_at": c.get("created_at"),
                }
                for c in comentarios
            ]
        }
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando opiniones: {ex}")


@router.post("/visita-perfil")
def registrar_visita_perfil(data: dict):
    """
    Registra una visita al perfil público de un artesano.
    🔗 FLUTTER: POST /api/vendedor/visita-perfil  Body: {"nombre": "..."}
    """
    nombre = (data.get("nombre") or "").strip()
    if not nombre:
        raise HTTPException(status_code=400, detail="Falta el nombre del artesano.")
    try:
        supabase.table("visitas_perfil").insert({"vendedor_nombre": nombre}).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error registrando la visita: {ex}")


# ─── PEDIDOS DEL VENDEDOR (pantalla "Mis Órdenes") ───────────────────────────

class ActualizarEstadoPedidoRequest(BaseModel):
    estado: str
    nombre_vendedor: str


def _items_propios(pedido: dict, nombres_prods: set) -> list:
    return [it for it in (pedido.get("productos") or []) if it.get("nombre") in nombres_prods]


@router.get("/{nombre_vendedor}/pedidos")
def pedidos_vendedor(nombre_vendedor: str, estado: Optional[str] = None, q: Optional[str] = None):
    """
    Lista de órdenes que contienen productos del vendedor, con estadísticas.
    🔗 FLUTTER: GET /api/vendedor/{nombre_vendedor}/pedidos?estado=&q=
    """
    try:
        prod_resp = (
            supabase.table("productos")
            .select("*")
            .eq("creador", nombre_vendedor)
            .execute()
        )
        productos_vendedor = prod_resp.data or []
        nombres_prods = {p.get("nombre") for p in productos_vendedor if p.get("nombre")}
        imagenes_prod = {
            p.get("nombre"): (p.get("imagen_url") or p.get("imagen") or p.get("img") or "")
            for p in productos_vendedor
        }

        todos = (
            supabase.table("pedidos")
            .select("*")
            .order("created_at", desc=True)
            .execute()
            .data
            or []
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando pedidos del vendedor: {ex}")

    ahora = datetime.now(timezone.utc)
    hace_30 = ahora - timedelta(days=30)

    total_ordenes = 0
    nuevas_ordenes = 0
    completadas = 0
    canceladas = 0
    ingresos_totales = 0.0
    filas = []

    estado_filtro = _canonizar_estado_vendedor(estado) if estado else None
    texto_busqueda = (q or "").strip().lower()

    for pedido in todos:
        items = _items_propios(pedido, nombres_prods)
        if not items:
            continue

        total_ordenes += 1
        estado_item = _estado_normal(items[0].get("estado") or pedido.get("estado"))
        subtotal = sum(
            _precio_float(it.get("precio")) * _cantidad_int(it.get("cantidad") or 1)
            for it in items
        )

        try:
            fecha = datetime.fromisoformat((pedido.get("created_at") or "").replace("Z", "+00:00"))
        except Exception:
            fecha = None

        if fecha is not None and fecha >= hace_30:
            if estado_item == "pendiente":
                nuevas_ordenes += 1
            elif estado_item == "entregado":
                completadas += 1
                ingresos_totales += subtotal
            elif estado_item == "cancelado":
                canceladas += 1

        orden_id = _formato_orden_id(pedido.get("id"))
        cliente_nombre = pedido.get("comprador_nombre") or "Cliente"

        if estado_filtro and estado_item != estado_filtro:
            continue
        if texto_busqueda and texto_busqueda not in orden_id.lower() and texto_busqueda not in cliente_nombre.lower():
            continue

        filas.append({
            "id": pedido.get("id"),
            "orden": orden_id,
            "cliente_nombre": cliente_nombre,
            "cliente_id": pedido.get("comprador_id"),
            "ubicacion": pedido.get("direccion") or "Panamá",
            "telefono": pedido.get("telefono"),
            "productos": [
                {
                    "nombre": it.get("nombre") or "Producto",
                    "imagen_url": it.get("img") or it.get("imagen") or imagenes_prod.get(it.get("nombre"), ""),
                    "cantidad": _cantidad_int(it.get("cantidad") or 1),
                }
                for it in items
            ],
            "cantidad_productos": len(items),
            "total": round(subtotal, 2),
            "estado": estado_item,
            "estado_label": _vendedor_estado_label(estado_item),
            "fecha": pedido.get("created_at"),
        })

    return {
        "pedidos": filas,
        "estadisticas": {
            "total_ordenes": total_ordenes,
            "nuevas_ordenes": nuevas_ordenes,
            "completadas": completadas,
            "canceladas": canceladas,
            "ingresos_totales": round(ingresos_totales, 2),
        },
    }


@router.patch("/pedidos/{pedido_id}/estado")
def actualizar_estado_pedido(pedido_id: str, req: ActualizarEstadoPedidoRequest):
    """
    Actualiza el estado de los ítems de un pedido que pertenecen a este vendedor.
    🔗 FLUTTER: PATCH /api/vendedor/pedidos/{pedido_id}/estado
    Body: { "estado": "Aceptada" | "Enviado" | "Completada" | "Cancelada" | "Pendiente", "nombre_vendedor": "..." }
    """
    nuevo_estado = _canonizar_estado_vendedor(req.estado)
    if nuevo_estado not in ESTADOS_CANONICOS_VALIDOS:
        raise HTTPException(status_code=400, detail="Estado inválido.")

    try:
        resp = supabase.table("pedidos").select("*").eq("id", pedido_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Pedido no encontrado.")
        pedido = resp.data[0]

        prod_resp = (
            supabase.table("productos").select("nombre").eq("creador", req.nombre_vendedor).execute()
        )
        nombres_prods = {p.get("nombre") for p in (prod_resp.data or [])}

        productos = pedido.get("productos") or []
        actualizado = False
        for item in productos:
            if item.get("nombre") in nombres_prods:
                item["estado"] = nuevo_estado
                actualizado = True

        if not actualizado:
            raise HTTPException(status_code=403, detail="Este pedido no contiene productos de este vendedor.")

        supabase.table("pedidos").update({"productos": productos}).eq("id", pedido_id).execute()

        # Si todos los ítems del pedido (de todos los vendedores involucrados)
        # comparten ahora el mismo estado, se refleja también en el pedido.
        estados_unicos = {it.get("estado") for it in productos}
        if len(estados_unicos) == 1:
            supabase.table("pedidos").update({"estado": nuevo_estado}).eq("id", pedido_id).execute()

        return {"success": True, "estado": nuevo_estado, "estado_label": _vendedor_estado_label(nuevo_estado)}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.get("/{nombre_vendedor}/pedidos/mapa")
def pedidos_vendedor_mapa(nombre_vendedor: str, estado: Optional[str] = None):
    """
    Puntos georreferenciados de los pedidos del vendedor para el mapa de seguimiento.
    🔗 FLUTTER: GET /api/vendedor/{nombre_vendedor}/pedidos/mapa?estado=
    """
    try:
        prod_resp = supabase.table("productos").select("nombre").eq("creador", nombre_vendedor).execute()
        nombres_prods = {p.get("nombre") for p in (prod_resp.data or [])}
        todos = (
            supabase.table("pedidos")
            .select("*")
            .order("created_at", desc=True)
            .execute()
            .data
            or []
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando el mapa de pedidos: {ex}")

    estado_filtro = _canonizar_estado_vendedor(estado) if estado else None
    ocupadas: dict = {}
    puntos = []

    for pedido in todos:
        items = _items_propios(pedido, nombres_prods)
        if not items:
            continue

        estado_item = _estado_normal(items[0].get("estado") or pedido.get("estado"))

        if estado_filtro:
            if estado_item != estado_filtro:
                continue
        elif estado_item == "cancelado":
            # Por defecto no saturamos el mapa con pedidos cancelados.
            continue

        ubicacion = pedido.get("direccion") or "Panamá"
        lat, lng = _get_coords(ubicacion)

        # Pequeño desplazamiento determinístico para que los pines de una
        # misma ciudad no queden exactamente superpuestos.
        clave = ubicacion.lower()
        n = ocupadas.get(clave, 0)
        ocupadas[clave] = n + 1
        angulo = n * 0.9
        radio = 0.01 * (1 + n // 8)
        lat += radio * math.cos(angulo)
        lng += radio * math.sin(angulo)

        subtotal = sum(
            _precio_float(it.get("precio")) * _cantidad_int(it.get("cantidad") or 1)
            for it in items
        )

        puntos.append({
            "id": pedido.get("id"),
            "orden": _formato_orden_id(pedido.get("id")),
            "cliente_nombre": pedido.get("comprador_nombre") or "Cliente",
            "ubicacion": ubicacion,
            "lat": lat,
            "lng": lng,
            "estado": estado_item,
            "estado_label": _mapa_estado_label(estado_item),
            "total": round(subtotal, 2),
            "telefono": pedido.get("telefono"),
            "fecha": pedido.get("created_at"),
        })

    return {"pedidos": puntos}
