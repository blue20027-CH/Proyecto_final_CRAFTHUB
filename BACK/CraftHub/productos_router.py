from fastapi import APIRouter, HTTPException, status, UploadFile, File
from pydantic import BaseModel
from typing import List, Optional
import uuid
from supabase_client import supabase

router = APIRouter(
    prefix="/productos",
    tags=["Productos y Favoritos"]
)

class ComentarioCreate(BaseModel):
    producto_id: int
    nombre: Optional[str] = "Visitante"
    comentario: str
    calificacion: Optional[float] = None
    foto_url: Optional[str] = None

class FavoritoToggle(BaseModel):
    producto_id: int
    user_id: str

class ProductoUpdate(BaseModel):
    nombre: str
    precio: float
    stock: int = 0
    categoria: str = "Artesania"
    descripcion: Optional[str] = None
    img: Optional[str] = None
    tallas: Optional[str] = None  # "S,M,L,XL" — solo Vestir/Calzado

class ProductoNuevo(BaseModel):
    nombre: str
    precio: float
    stock: int = 0
    categoria: str = "Artesania"
    descripcion: Optional[str] = None
    img: Optional[str] = None
    color: str = "#C4A882"
    creador: str
    tallas: Optional[str] = None  # "S,M,L,XL" — solo Vestir/Calzado


@router.get("/", response_model=List[dict])
def obtener_productos(categoria: Optional[str] = None, busqueda: Optional[str] = None):
    try:
        # Los administradores pueden marcar productos como `oculto = true` desde
        # Supabase para censurarlos sin borrar la fila; aquí (listado público
        # que ven los compradores) los filtramos fuera.
        query = supabase.table("productos").select("*").eq("oculto", False)
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


def _rating_de_producto(producto_id: int) -> tuple[float, int]:
    """Promedio y total de calificaciones reales en `comentarios` para un producto."""
    try:
        resp = supabase.table("comentarios").select("calificacion").eq("producto_id", producto_id).execute()
        calificaciones = [c["calificacion"] for c in (resp.data or []) if c.get("calificacion") is not None]
    except Exception:
        calificaciones = []
    if not calificaciones:
        return 0.0, 0
    return round(sum(calificaciones) / len(calificaciones), 1), len(calificaciones)


@router.post("/subir-foto")
async def subir_foto_producto(file: UploadFile = File(...)):
    """
    Sube una foto de producto al Storage de Supabase y devuelve su URL pública.
    🔗 FLUTTER: POST /productos/subir-foto (multipart, campo "file")
    """
    try:
        contenido = await file.read()
        extension = file.filename.split(".")[-1] if file.filename else "jpg"
        nombre_archivo = f"producto_{uuid.uuid4().hex[:10]}.{extension}"
        bucket = "productos"
        supabase.storage.from_(bucket).upload(
            nombre_archivo, contenido, {"content-type": file.content_type or "image/jpeg"}
        )
        url = supabase.storage.from_(bucket).get_public_url(nombre_archivo)
        return {"success": True, "url": url}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error al subir la imagen: {str(ex)}")


@router.post("/", status_code=status.HTTP_201_CREATED)
def crear_producto(producto: ProductoNuevo):
    """
    Crea un producto nuevo para el vendedor.
    🔗 FLUTTER: POST /productos/
    """
    if not producto.nombre.strip():
        raise HTTPException(status_code=400, detail="El nombre no puede estar vacío.")
    try:
        resp = supabase.table("productos").insert(producto.model_dump(exclude_none=True)).execute()
        if not resp.data:
            raise HTTPException(status_code=400, detail="No se pudo crear el producto.")
        return resp.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el producto: {str(e)}")


@router.get("/{producto_id}")
def obtener_producto(producto_id: int):
    """
    Detalle de un producto, con calificación y total de valoraciones
    calculados en vivo a partir de la tabla `comentarios`.
    🔗 FLUTTER: GET /productos/{id}
    """
    try:
        # Un producto censurado (oculto = true) no se muestra al comprador ni
        # aunque intente entrar al detalle con el link directo.
        resp = (
            supabase.table("productos")
            .select("*")
            .eq("id", producto_id)
            .eq("oculto", False)
            .execute()
        )
        productos = resp.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar el producto: {str(e)}")

    if not productos:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")

    producto = productos[0]
    calificacion, total = _rating_de_producto(producto_id)
    producto["calificacion"] = calificacion
    producto["total_valoraciones"] = total
    return producto


@router.put("/{producto_id}")
def actualizar_producto(producto_id: int, producto: ProductoUpdate):
    """
    Edita nombre/precio/stock/categoría/descripción/imagen de un producto
    ya existente (no toca quién es el creador).
    🔗 FLUTTER: PUT /productos/{id}
    """
    try:
        datos = producto.model_dump(exclude_none=True)
        resp = supabase.table("productos").update(datos).eq("id", producto_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        return resp.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el producto: {str(e)}")


@router.delete("/{producto_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_producto(producto_id: int):
    """
    Elimina un producto por ID.
    🔗 FLUTTER: DELETE /productos/{id}
    """
    try:
        supabase.table("productos").delete().eq("id", producto_id).execute()
        return
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar el producto: {str(e)}")


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
        productos = (
            supabase.table("productos")
            .select("*")
            .in_("id", ids)
            .eq("oculto", False)
            .execute()
            .data
            or []
        )
        return {"favoritos": productos}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


def _notificar_favorito(producto_id: int) -> None:
    """Avisa al vendedor (tabla `notificaciones`) que a alguien le gustó su producto."""
    try:
        prod_resp = supabase.table("productos").select("nombre, creador").eq("id", producto_id).execute()
        productos = prod_resp.data or []
        if not productos:
            return
        producto = productos[0]
        creador = (producto.get("creador") or "").strip()
        if not creador:
            return

        perfil_resp = supabase.table("perfiles").select("user_id").eq("nombre", creador).execute()
        perfiles = perfil_resp.data or []
        if not perfiles:
            return
        vendedor_user_id = perfiles[0].get("user_id")
        if not vendedor_user_id:
            return

        supabase.table("notificaciones").insert({
            "user_id": vendedor_user_id,
            "titulo": "Nuevo favorito",
            "mensaje": f'A alguien le gustó tu producto "{producto.get("nombre") or "Producto"}"',
            "leida": False,
        }).execute()
    except Exception:
        # Una notificación fallida no debe romper el flujo de marcar favorito.
        pass


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
        _notificar_favorito(data["producto_id"])
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
            _notificar_favorito(data.producto_id)
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
    if data.calificacion is not None and not (0 <= data.calificacion <= 5):
        raise HTTPException(status_code=400, detail="La calificación debe estar entre 0 y 5.")

    # El avatar se toma del perfil real del usuario (si está logueado), no de
    # lo que mande el cliente, para que siempre refleje su foto vigente.
    avatar_url = None
    if user_id:
        try:
            perfil_resp = supabase.table("perfiles").select("foto").eq("user_id", user_id).maybe_single().execute()
            avatar_url = (perfil_resp.data or {}).get("foto") if perfil_resp else None
        except Exception:
            avatar_url = None

    try:
        nuevo = {
            "producto_id": data.producto_id,
            "user_id": user_id,
            "nombre": data.nombre,
            "comentario": data.comentario.strip(),
            "calificacion": data.calificacion,
            "foto_url": data.foto_url,
            "avatar_url": avatar_url,
        }
        resp = supabase.table("comentarios").insert(nuevo).execute()
        return {"status": "success", "message": "Comentario publicado", "data": resp.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar el comentario: {str(e)}")