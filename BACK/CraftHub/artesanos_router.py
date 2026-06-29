"""
artesanos_router.py
Endpoint para listar artesanos/vendedores combinando datos de
'perfiles' (rol=Vendedor) con estadísticas calculadas desde 'productos'.
"""

from fastapi import APIRouter, HTTPException
from typing import Optional, List
from supabase_client import supabase

router = APIRouter(prefix="/artesanos", tags=["Artesanos"])


@router.get("/")
def listar_artesanos(categoria: Optional[str] = None, provincia: Optional[str] = None):
    """
    Lista todos los vendedores (rol=Vendedor) con estadísticas
    calculadas a partir de sus productos.
    🔗 FLUTTER: GET /artesanos?categoria=X&provincia=Y
    """
    try:
        # 1. Traer perfiles de vendedores
        perfiles_resp = supabase.table("perfiles").select("*").eq("rol", "Vendedor").execute()
        perfiles = perfiles_resp.data or []

        # 2. Traer todos los productos para calcular estadísticas
        productos_resp = supabase.table("productos").select("*").execute()
        productos = productos_resp.data or []

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cargar artesanos: {str(e)}")

    artesanos = []
    for perfil in perfiles:
        nombre = (perfil.get("nombre") or "").strip()
        if not nombre:
            continue

        # Productos de este vendedor (match flexible por nombre, ya que
        # 'creador' en productos guarda el nombre, no el user_id)
        productos_vendedor = [
            p for p in productos
            if (p.get("creador") or "").strip().lower() == nombre.lower()
        ]

        if not productos_vendedor:
            continue  # opcional: omitir vendedores sin productos

        categorias_vendedor = list({
            (p.get("categoria") or "").strip()
            for p in productos_vendedor if p.get("categoria")
        })
        provincias_vendedor = list({
            (p.get("origen") or p.get("region") or "").strip()
            for p in productos_vendedor if (p.get("origen") or p.get("region"))
        })

        # Filtros
        if categoria and categoria not in categorias_vendedor:
            continue
        if provincia and provincia not in provincias_vendedor:
            continue

        artesanos.append({
        "id": perfil.get("user_id") or perfil.get("id"),
        "nombre": nombre,
        "foto_url": perfil.get("ft") or perfil.get("foto") or "",
        "foto_portada": perfil.get("foto_portada") or "",
        "categoria": perfil.get("categoria") or "",  # ← agrega esta línea
        "ubicacion": perfil.get("ubicacion") or (provincias_vendedor[0] if provincias_vendedor else ""),
        "telefono": perfil.get("telefono") or "",
        "categorias": categorias_vendedor,
        "especialidad": categorias_vendedor[0] if categorias_vendedor else "Artesanías",
        "total_productos": len(productos_vendedor),
        "descripcion": perfil.get("descripcion") or "",
})
       

    return {"total": len(artesanos), "artesanos": artesanos}


@router.get("/{nombre}")
def detalle_artesano(nombre: str):
    """
    Detalle de un artesano y sus productos.
    🔗 FLUTTER: GET /artesanos/{nombre}
    """
    try:
        perfil_resp = supabase.table("perfiles").select("*").eq("nombre", nombre).execute()
        if not perfil_resp.data:
            raise HTTPException(status_code=404, detail="Artesano no encontrado.")
        perfil = perfil_resp.data[0]

        productos_resp = supabase.table("productos").select("*").eq("creador", nombre).execute()
        productos = productos_resp.data or []

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    categorias = list({(p.get("categoria") or "").strip() for p in productos if p.get("categoria")})

   
    return {
        "id": perfil.get("user_id") or perfil.get("id"),
        "nombre": perfil.get("nombre"),
        "foto_url": perfil.get("ft") or perfil.get("foto") or "",
        "foto_portada": perfil.get("foto_portada") or "",
        "categoria": perfil.get("categoria") or "",  # ← agrega esta línea
        "ubicacion": perfil.get("ubicacion") or "",
        "telefono": perfil.get("telefono") or "",
        "descripcion": perfil.get("descripcion") or "",
        "categorias": categorias,
        "total_productos": len(productos),
        "productos": productos,
}