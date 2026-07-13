"""
tarjetas_router.py
Tarjetas de pago guardadas por el comprador (solo datos enmascarados: marca,
últimos 4 dígitos, titular, vencimiento — nunca número completo ni CVV).
Cada acción de escritura (agregar, eliminar, marcar predeterminada) exige
reautenticación con la contraseña de la cuenta (ver auth_router._verificar_password).
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from typing import Literal, Optional
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase
from auth_router import _verificar_password

router = APIRouter(prefix="/api/tarjetas", tags=["Tarjetas"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

Marca = Literal["Visa", "Mastercard", "Amex", "Otra"]


class AgregarTarjetaRequest(BaseModel):
    user_id: str
    email: EmailStr
    password: str
    marca: Marca
    ultimos_4: str = Field(..., min_length=4, max_length=4)
    nombre_titular: str = Field(..., min_length=1)
    mes_vencimiento: int = Field(..., ge=1, le=12)
    anio_vencimiento: int = Field(..., ge=2000)
    alias: Optional[str] = None
    predeterminada: bool = False


class PasswordConfirmRequest(BaseModel):
    email: EmailStr
    password: str


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

def _desmarcar_predeterminadas(user_id: str):
    supabase.table("tarjetas_guardadas").update({"predeterminada": False}).eq("user_id", user_id).execute()


# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.get("/{user_id}")
def listar_tarjetas(user_id: str):
    """
    Lista las tarjetas guardadas (enmascaradas) de un comprador.
    🔗 FLUTTER: GET /api/tarjetas/{user_id}
    """
    try:
        resp = (
            supabase.table("tarjetas_guardadas")
            .select("*")
            .eq("user_id", user_id)
            .order("predeterminada", desc=True)
            .order("created_at", desc=True)
            .execute()
        )
        return {"tarjetas": resp.data}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.post("/", status_code=status.HTTP_201_CREATED)
def agregar_tarjeta(req: AgregarTarjetaRequest):
    """
    Guarda una tarjeta nueva (solo datos enmascarados). Exige la contraseña
    de la cuenta antes de insertar.
    🔗 FLUTTER: POST /api/tarjetas/
    """
    if not req.ultimos_4.isdigit():
        raise HTTPException(status_code=400, detail="Los últimos 4 dígitos deben ser numéricos.")

    _verificar_password(req.email, req.password)

    try:
        if req.predeterminada:
            _desmarcar_predeterminadas(req.user_id)

        result = supabase.table("tarjetas_guardadas").insert({
            "user_id":          req.user_id,
            "marca":            req.marca,
            "ultimos_4":        req.ultimos_4,
            "nombre_titular":   req.nombre_titular,
            "mes_vencimiento":  req.mes_vencimiento,
            "anio_vencimiento": req.anio_vencimiento,
            "alias":            req.alias,
            "predeterminada":   req.predeterminada,
        }).execute()
        return {"success": True, "tarjeta": result.data[0] if result.data else None}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"No se pudo guardar la tarjeta: {ex}")


@router.delete("/{tarjeta_id}")
def eliminar_tarjeta(tarjeta_id: str, req: PasswordConfirmRequest):
    """
    Elimina una tarjeta guardada. Exige la contraseña de la cuenta.
    🔗 FLUTTER: DELETE /api/tarjetas/{tarjeta_id}
    Body: { "email": "...", "password": "..." }
    """
    _verificar_password(req.email, req.password)
    try:
        resp = supabase.table("tarjetas_guardadas").select("id").eq("id", tarjeta_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Tarjeta no encontrada.")
        supabase.table("tarjetas_guardadas").delete().eq("id", tarjeta_id).execute()
        return {"success": True}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.patch("/{tarjeta_id}/predeterminada")
def marcar_predeterminada(tarjeta_id: str, req: PasswordConfirmRequest):
    """
    Marca una tarjeta como predeterminada (y desmarca las demás del mismo
    usuario). Exige la contraseña de la cuenta.
    🔗 FLUTTER: PATCH /api/tarjetas/{tarjeta_id}/predeterminada
    Body: { "email": "...", "password": "..." }
    """
    _verificar_password(req.email, req.password)
    try:
        resp = supabase.table("tarjetas_guardadas").select("user_id").eq("id", tarjeta_id).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Tarjeta no encontrada.")
        user_id = resp.data[0]["user_id"]

        _desmarcar_predeterminadas(user_id)
        supabase.table("tarjetas_guardadas").update({"predeterminada": True}).eq("id", tarjeta_id).execute()
        return {"success": True}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))
