"""
carrito_router.py
Endpoints para manejar el carrito de compras.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from supabase_client import supabase

router = APIRouter(prefix="/api/carrito", tags=["Carrito"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class CrearCarritoRequest(BaseModel):
    user_id: str
    nombre: str = "Mi carrito"

class AgregarItemRequest(BaseModel):
    carrito_id: str
    producto_id: int
    nombre_producto: str
    imagen_url: Optional[str] = ""
    artesano: Optional[str] = ""
    precio: float
    cantidad: int = 1

class ActualizarCantidadRequest(BaseModel):
    cantidad: int

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/{user_id}")
def obtener_carritos(user_id: str):
    """
    Obtiene todos los carritos del usuario con sus items.
    🔗 FLUTTER: GET /api/carrito/{user_id}
    """
    try:
        carritos = supabase.table("carritos").select("*").eq("user_id", user_id).execute().data or []
        for carrito in carritos:
            items = supabase.table("carrito_items").select("*").eq("carrito_id", carrito["id"]).execute().data or []
            carrito["items"] = items
        return {"carritos": carritos}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/crear")
def crear_carrito(req: CrearCarritoRequest):
    """
    Crea un nuevo carrito para el usuario.
    🔗 FLUTTER: POST /api/carrito/crear
    """
    try:
        result = supabase.table("carritos").insert({
            "user_id": req.user_id,
            "nombre": req.nombre,
        }).execute()
        return {"success": True, "carrito": result.data[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/agregar")
def agregar_item(req: AgregarItemRequest):
    """
    Agrega un producto al carrito. Si ya existe, suma la cantidad.
    🔗 FLUTTER: POST /api/carrito/agregar
    """
    try:
        # Verificar si el producto ya está en el carrito
        existe = supabase.table("carrito_items")\
            .select("*")\
            .eq("carrito_id", req.carrito_id)\
            .eq("producto_id", req.producto_id)\
            .execute().data

        if existe:
            nueva_cantidad = existe[0]["cantidad"] + req.cantidad
            supabase.table("carrito_items")\
                .update({"cantidad": nueva_cantidad})\
                .eq("id", existe[0]["id"])\
                .execute()
            return {"success": True, "action": "updated", "cantidad": nueva_cantidad}
        else:
            result = supabase.table("carrito_items").insert({
                "carrito_id": req.carrito_id,
                "producto_id": req.producto_id,
                "nombre_producto": req.nombre_producto,
                "imagen_url": req.imagen_url,
                "artesano": req.artesano,
                "precio": req.precio,
                "cantidad": req.cantidad,
            }).execute()
            return {"success": True, "action": "added", "item": result.data[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/item/{item_id}")
def actualizar_cantidad(item_id: str, req: ActualizarCantidadRequest):
    """
    Actualiza la cantidad de un item del carrito.
    🔗 FLUTTER: PATCH /api/carrito/item/{item_id}
    """
    try:
        if req.cantidad <= 0:
            supabase.table("carrito_items").delete().eq("id", item_id).execute()
            return {"success": True, "action": "deleted"}
        supabase.table("carrito_items").update({"cantidad": req.cantidad}).eq("id", item_id).execute()
        return {"success": True, "action": "updated", "cantidad": req.cantidad}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/item/{item_id}")
def eliminar_item(item_id: str):
    """
    Elimina un item del carrito.
    🔗 FLUTTER: DELETE /api/carrito/item/{item_id}
    """
    try:
        supabase.table("carrito_items").delete().eq("id", item_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/vaciar/{carrito_id}")
def vaciar_carrito(carrito_id: str):
    """
    Elimina todos los items de un carrito.
    🔗 FLUTTER: DELETE /api/carrito/vaciar/{carrito_id}
    """
    try:
        supabase.table("carrito_items").delete().eq("carrito_id", carrito_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/eliminar/{carrito_id}")
def eliminar_carrito(carrito_id: str):
    """
    Elimina un carrito completo con todos sus items.
    🔗 FLUTTER: DELETE /api/carrito/eliminar/{carrito_id}
    """
    try:
        supabase.table("carritos").delete().eq("id", carrito_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))