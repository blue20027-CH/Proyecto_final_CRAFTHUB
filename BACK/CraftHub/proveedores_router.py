"""
proveedores_router.py
Red de proveedores de materiales: los vendedores buscan y agregan
proveedores de insumos (cuero, hilos, cerámica, etc.) para su taller.
"""

from typing import List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/proveedores", tags=["Proveedores"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class ProveedorRequest(BaseModel):
    nombre: str = Field(..., min_length=1)
    propietario: Optional[str] = None
    categoria: str
    ubicacion: str
    descripcion: Optional[str] = None
    materiales: List[str] = []
    imagen_url: Optional[str] = None
    telefono: Optional[str] = None
    email: Optional[str] = None
    creado_por: Optional[str] = None  # nombre del vendedor que lo agrega


def _precio_float(valor) -> float:
    try:
        return float(valor or 0)
    except Exception:
        return 0.0


def _serializar(p: dict) -> dict:
    return {
        "id": str(p.get("id", "")),
        "nombre": p.get("nombre") or "Proveedor",
        "propietario": p.get("propietario") or "",
        "categoria": p.get("categoria") or "General",
        "ubicacion": p.get("ubicacion") or "Panamá",
        "descripcion": p.get("descripcion") or "",
        "materiales": p.get("materiales") or [],
        "calificacion": _precio_float(p.get("calificacion")),
        "total_resenas": int(p.get("total_resenas") or 0),
        "verificado": bool(p.get("verificado") or False),
        "imagen_url": p.get("imagen_url") or "",
        "telefono": p.get("telefono") or "",
        "email": p.get("email") or "",
        "creado_por": p.get("creado_por"),
        "created_at": p.get("created_at"),
    }


# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("")
def listar_proveedores(
    q: Optional[str] = None,
    categoria: Optional[str] = None,
    ubicacion: Optional[str] = None,
    calificacion_min: Optional[float] = None,
    orden: str = "relevantes",
):
    """
    Lista proveedores de materiales con filtros de búsqueda.
    🔗 FLUTTER: GET /api/proveedores?q=&categoria=&ubicacion=&calificacion_min=&orden=
    """
    try:
        resp = supabase.table("proveedores").select("*").execute()
        proveedores = [_serializar(p) for p in (resp.data or [])]
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando proveedores: {ex}")

    if q:
        texto = q.strip().lower()
        proveedores = [
            p for p in proveedores
            if texto in p["nombre"].lower()
            or texto in p["descripcion"].lower()
            or any(texto in m.lower() for m in p["materiales"])
        ]
    if categoria and categoria != "Todas las categorías":
        proveedores = [p for p in proveedores if p["categoria"] == categoria]
    if ubicacion and ubicacion != "Todas":
        proveedores = [p for p in proveedores if p["ubicacion"] == ubicacion]
    if calificacion_min:
        proveedores = [p for p in proveedores if p["calificacion"] >= calificacion_min]

    if orden == "calificacion":
        proveedores.sort(key=lambda p: p["calificacion"], reverse=True)
    elif orden == "recientes":
        proveedores.sort(key=lambda p: p.get("created_at") or "", reverse=True)
    else:  # relevantes: verificados y mejor calificados primero
        proveedores.sort(key=lambda p: (p["verificado"], p["calificacion"], p["total_resenas"]), reverse=True)

    categorias_disponibles = sorted({p["categoria"] for p in proveedores if p["categoria"]})

    return {"proveedores": proveedores, "total": len(proveedores), "categorias": categorias_disponibles}


@router.get("/{proveedor_id}")
def detalle_proveedor(proveedor_id: str):
    """
    🔗 FLUTTER: GET /api/proveedores/{id}
    """
    try:
        resp = supabase.table("proveedores").select("*").eq("id", proveedor_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Proveedor no encontrado.")
        return _serializar(resp.data[0])
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error cargando el proveedor: {ex}")


@router.post("")
def crear_proveedor(req: ProveedorRequest):
    """
    Agrega un nuevo proveedor a la red (botón "Agregar proveedor" /
    "Quiero ser proveedor").
    🔗 FLUTTER: POST /api/proveedores
    """
    try:
        data = {
            "nombre": req.nombre.strip(),
            "propietario": (req.propietario or "").strip() or None,
            "categoria": req.categoria,
            "ubicacion": req.ubicacion,
            "descripcion": (req.descripcion or "").strip() or None,
            "materiales": req.materiales,
            "imagen_url": req.imagen_url,
            "telefono": (req.telefono or "").strip() or None,
            "email": (req.email or "").strip() or None,
            "creado_por": req.creado_por,
            "calificacion": 0,
            "total_resenas": 0,
            "verificado": False,
        }
        resultado = supabase.table("proveedores").insert(data).execute()
        if not resultado.data:
            raise HTTPException(status_code=400, detail="No se pudo crear el proveedor.")
        return {"success": True, "proveedor": _serializar(resultado.data[0])}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error creando el proveedor: {ex}")
