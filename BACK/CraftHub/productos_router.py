from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
from supabase_client import supabase

router = APIRouter(
    prefix="/productos",
    tags=["Productos y Favoritos"]
)

class ComentarioCreate(BaseModel):
    producto_id: int
    nombre: Optional[str] = "Visitante"
    comentario: str

class FavoritoToggle(BaseModel):
    producto_id: int
    user_id: str


@router.get("/", response_model=List[dict])
def obtener_productos(categoria: Optional[str] = None, busqueda: Optional[str] = None):
    try:
        query = supabase.table("productos").select("*")
        if categoria and categoria != "Todos":
            query = query.eq("categoria", categoria)
        resp = query.execute()
        productos = resp.data or []
        if busqueda:
            b = busqueda.lower()
            productos = [
                p for p in productos if
                b in (p.get("nombre") or "").lower() or
                b in (p.get("categoria") or "").lower() or
                b in (p.get("origen") or p.get("region") or "").lower() or
                b in (p.get("creador") or "").lower()
            ]
        return productos
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar productos: {str(e)}")


@router.get("/favoritos/{user_id}")
def obtener_favoritos(user_id: str):
    """
    Obtiene los productos favoritos completos del usuario.
    🔗 FLUTTER: GET /productos/favoritos/{user_id}
    """
    try:
        favs = supabase.table("favoritos").select("producto_id").eq("user_id", user_id).execute().data or []
        ids = [f["producto_id"] for f in favs]
        if not ids:
            return {"favoritos": []}
        productos = supabase.table("productos").select("*").in_("id", ids).execute().data or []
        return {"favoritos": productos}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.post("/favoritos")
def agregar_favorito(data: dict):
    """
    Agrega un producto a favoritos.
    🔗 FLUTTER: POST /productos/favoritos
    """
    try:
        supabase.table("favoritos").insert({
            "user_id": data["user_id"],
            "producto_id": data["producto_id"],
        }).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.delete("/favoritos/{user_id}/{producto_id}")
def quitar_favorito(user_id: str, producto_id: int):
    """
    Quita un producto de favoritos.
    🔗 FLUTTER: DELETE /productos/favoritos/{user_id}/{producto_id}
    """
    try:
        supabase.table("favoritos").delete().eq("user_id", user_id).eq("producto_id", producto_id).execute()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.post("/favoritos/toggle")
def toggle_favorito(data: FavoritoToggle):
    """
    Toggle favorito.
    🔗 FLUTTER: POST /productos/favoritos/toggle
    """
    try:
        existe = supabase.table("favoritos").select("*").eq("user_id", data.user_id).eq("producto_id", data.producto_id).execute()
        if existe.data:
            supabase.table("favoritos").delete().eq("user_id", data.user_id).eq("producto_id", data.producto_id).execute()
            return {"status": "success", "action": "removed"}
        else:
            supabase.table("favoritos").insert({"user_id": data.user_id, "producto_id": data.producto_id}).execute()
            return {"status": "success", "action": "added"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.get("/{producto_id}/comentarios", response_model=List[dict])
def obtener_comentarios(producto_id: int):
    try:
        resp = supabase.table("comentarios").select("*").eq("producto_id", producto_id).order("created_at", desc=True).limit(20).execute()
        return resp.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener comentarios: {str(e)}")


@router.post("/comentarios", status_code=status.HTTP_201_CREATED)
def publicar_comentario(data: ComentarioCreate, user_id: Optional[str] = None):
    if not data.comentario.strip():
        raise HTTPException(status_code=400, detail="El comentario no puede estar vacío.")
    try:
        nuevo = {
            "producto_id": data.producto_id,
            "user_id": user_id,
            "nombre": data.nombre,
            "comentario": data.comentario.strip()
        }
        resp = supabase.table("comentarios").insert(nuevo).execute()
        return {"status": "success", "message": "Comentario publicado", "data": resp.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar el comentario: {str(e)}")