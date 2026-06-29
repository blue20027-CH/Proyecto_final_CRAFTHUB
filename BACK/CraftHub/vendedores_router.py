from collections import defaultdict
from typing import Optional

from fastapi import APIRouter, HTTPException

from supabase_client import supabase

router = APIRouter(prefix="/api/vendedor", tags=["Vendedor"])


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
        return {
            "nombre_vendedor": nombre_vendedor,
            "ingresos_total": round(ingresos_total, 2),
            "variacion_ingresos": 0,
            "ingresos_mensuales": [0, 0, 0, 0, 0, round(ingresos_total, 2)],
            "etiquetas_meses": ["Ene", "Feb", "Mar", "Abr", "May", "Jun"],
            "top_productos": top_productos,
            "promedio_evaluacion": 0,
            "total_evaluaciones": 0,
            "distribucion_evaluaciones": {"5": 0, "4": 0, "3": 0, "2": 0, "1": 0},
            "clientes_felices": pedidos_totales,
            "nuevas_opiniones": 0,
            "pedidos_totales": pedidos_totales,
            "pendientes_enviar": pendientes,
            "productos_activos": productos_activos,
            "visitas_tienda": 0,
        }
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando dashboard del vendedor: {ex}")