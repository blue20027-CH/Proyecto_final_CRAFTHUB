from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import List, Optional
from supabase_client import supabase  # Tu cliente de Supabase configurado

router = APIRouter(
    prefix="/productos",
    tags=["Productos y Favoritos"]
)

# ─── SCHEMAS DE REQUERIMIENTOS (PYDANTIC) ───────────────────────────

class ComentarioCreate(BaseModel):
    producto_id: int
    nombre: Optional[str] = "Visitante"
    comentario: str

class FavoritoToggle(BaseModel):
    producto_id: int
    user_id: str


# ─── ENDPOINTS DE PRODUCTOS ─────────────────────────────────────────

@router.get("/", response_model=List[dict])
def obtener_productos(categoria: Optional[str] = None, busqueda: Optional[str] = None):
    """
    Obtiene la lista de productos desde Supabase con filtros opcionales de categoría y búsqueda.
    """
    try:
        query = supabase.table("productos").select("*")
        
        if categoria and categoria != "Todos":
            query = query.eq("categoria", categoria)
            
        resp = query.execute()
        productos = resp.data or []

        # Filtrado por búsqueda en memoria (o puedes optimizarlo con ilike de Supabase si prefieres)
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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error al cargar productos: {str(e)}"
        )


# ─── ENDPOINTS DE FAVORITOS ─────────────────────────────────────────

@router.get("/favoritos/{user_id}", response_model=List[int])
def obtener_ids_favoritos(user_id: str):
    """
    Retorna únicamente una lista con los IDs de los productos favoritos del usuario.
    """
    try:
        resp = supabase.table("favoritos").select("producto_id").eq("user_id", user_id).execute()
        return [r["producto_id"] for r in (resp.data or [])]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error al cargar favoritos: {str(e)}"
        )

@router.post("/favoritos/toggle")
def toggle_favorito(data: FavoritoToggle):
    """
    Agrega o elimina un producto de los favoritos del usuario (Lógica Toggle).
    """
    try:
        # Verificar si ya existe en favoritos
        existe = supabase.table("favoritos")\
            .select("*")\
            .eq("user_id", data.user_id)\
            .eq("producto_id", data.producto_id)\
            .execute()

        if existe.data:
            # Si existe, lo removemos
            supabase.table("favoritos")\
                .delete()\
                .eq("user_id", data.user_id)\
                .eq("producto_id", data.producto_id)\
                .execute()
            return {"status": "success", "action": "removed", "message": "Eliminado de favoritos"}
        else:
            # Si no existe, lo agregamos
            supabase.table("favoritos")\
                .insert({"user_id": data.user_id, "producto_id": data.producto_id})\
                .execute()
            return {"status": "success", "action": "added", "message": "Agregado a favoritos"}
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error en la gestión de favoritos: {str(e)}"
        )


# ─── ENDPOINTS DE COMENTARIOS ───────────────────────────────────────

@router.get("/{producto_id}/comentarios", response_model=List[dict])
def obtener_comentarios(producto_id: int):
    """
    Obtiene los últimos 20 comentarios de un producto específico ordenados por fecha.
    """
    try:
        resp = supabase.table("comentarios")\
            .select("*")\
            .eq("producto_id", producto_id)\
            .order("created_at", desc=True)\
            .limit(20)\
            .execute()
        return resp.data or []
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error al obtener comentarios: {str(e)}"
        )

@router.post("/comentarios", status_code=status.HTTP_201_CREATED)
def publicar_comentario(data: ComentarioCreate, user_id: Optional[str] = None):
    """
    Registra un nuevo comentario para un producto. El `user_id` es opcional (para visitantes).
    """
    if not data.comentario.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="El comentario no puede estar vacío."
        )
        
    try:
        nuevo_comentario = {
            "producto_id": data.producto_id,
            "user_id": user_id,
            "nombre": data.nombre,
            "comentario": data.comentario.strip()
        }
        
        resp = supabase.table("comentarios").insert(nuevo_comentario).execute()
        return {"status": "success", "message": "Comentario publicado", "data": resp.data}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error al guardar el comentario: {str(e)}"
        )