from fastapi import FastAPI, HTTPException, status
from typing import List, Optional
from datetime import datetime, timedelta, timezone
from supabase_client import supabase  # Tu cliente de Supabase instanciado
from schemas import ProductoCreate, ProductoResponse, NotificacionResponse

app = FastAPI(title="CraftHub Vendedor API", version="1.0")

# ─── PRODUCTOS ──────────────────────────────────────────────────────────

@app.get("/productos", response_model=List[ProductoResponse])
def obtener_productos(vendedor: str, q: Optional[str] = None):
    """Obtiene los productos de un vendedor con opción de filtrado."""
    try:
        query = supabase.table("productos").select("*").eq("creador", vendedor)
        resp = query.execute()
        productos = resp.data or []
        
        if q:
            termino = q.strip().lower()
            productos = [
                p for p in productos
                if termino in (p.get("nombre") or "").lower()
                or termino in (p.get("categoria") or "").lower()
            ]
        return productos
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")

@app.post("/productos", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_producto(producto: ProductoCreate):
    """Inserta un nuevo producto en Supabase."""
    try:
        resp = supabase.table("productos").insert(producto.model_dump()).execute()
        if not resp.data:
            raise HTTPException(status_code=400, detail="No se pudo crear el producto.")
        return resp.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/productos/{producto_id}", response_model=ProductoResponse)
def actualizar_producto(producto_id: int, producto: ProductoCreate):
    """Actualiza un producto existente."""
    try:
        resp = supabase.table("productos").update(producto.model_dump()).eq("id", producto_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        return resp.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/productos/{producto_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_producto(producto_id: int):
    """Elimina un producto por ID."""
    try:
        supabase.table("productos").delete().eq("id", producto_id).execute()
        return
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── PEDIDOS Y ESTADÍSTICAS ──────────────────────────────────────────────

@app.get("/vendedor/stats")
def obtener_estadisticas(vendedor: str):
    """Calcula las ventas totales, de las últimas 24h y de los últimos 7 días."""
    try:
        # 1. Obtener productos del vendedor para saber cuáles le pertenecen
        prod_resp = supabase.table("productos").select("nombre").eq("creador", vendedor).execute()
        nombres_productos = [p["nombre"] for p in (prod_resp.data or [])]
        
        # 2. Obtener todos los pedidos
        pedidos_resp = supabase.table("pedidos").select("*").execute()
        todos_los_pedidos = pedidos_resp.data or []
        
        semana = 0.0
        reciente = 0.0
        total = 0.0
        
        ahora = datetime.now(timezone.utc)
        hace_7_dias = ahora - timedelta(days=7)
        hace_24_horas = ahora - timedelta(hours=24)

        for pedido in todos_los_pedidos:
            subtotal_pedido = 0.0
            pertenece_al_vendedor = False
            
            # Calcular cuánto de este pedido le pertenece a este vendedor
            for item in pedido.get("productos") or []:
                if item.get("nombre") in nombres_productos:
                    pertenece_al_vendedor = True
                    precio = float(str(item.get("precio", 0)).replace("$", "").replace(",", ""))
                    cantidad = int(item.get("cantidad", 1) or 1)
                    subtotal_pedido += precio * cantidad
            
            if pertenece_al_vendedor:
                total += subtotal_pedido
                try:
                    # Supabase suele regresar timestamps con formato ISO o Z
                    fecha_str = (pedido.get("created_at") or "").replace("Z", "+00:00")
                    fecha_pedido = datetime.fromisoformat(fecha_str)
                    
                    if fecha_pedido >= hace_7_dias:
                        semana += subtotal_pedido
                    if fecha_pedido >= hace_24_horas:
                        reciente += subtotal_pedido
                except ValueError:
                    pass  # Ignorar errores de parseo de fecha malformada

        return {
            "ganancias_totales": total,
            "ganancias_ultimos_7_dias": semana,
            "ganancias_ultimas_24_horas": reciente
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── NOTIFICACIONES ──────────────────────────────────────────────────────

@app.get("/notificaciones", response_model=List[NotificacionResponse])
def obtener_notificaciones(user_id: str):
    """Trae notificaciones no leídas ordenadas de la más reciente a la más antigua."""
    try:
        resp = supabase.table("notificaciones")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("leida", False)\
            .order("created_at", desc=True)\
            .execute()
        return resp.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.patch("/notificaciones/{noti_id}/leer")
def marcar_notificacion_leida(noti_id: int):
    """Marca una notificación como leída."""
    try:
        resp = supabase.table("notificaciones").update({"leida": True}).eq("id", noti_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Notificación no encontrada.")
        return {"status": "success", "message": "Notificación marcada como leída"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))