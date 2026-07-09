"""
auth_router.py
Traducción de screens/login.py (Flet) → FastAPI
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase

router = APIRouter(prefix="/api/auth", tags=["Auth"])

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    modo: str = "Comprador"  # "Comprador" | "Vendedor"


class RegistroRequest(BaseModel):
    nombre: str = Field(..., min_length=1)
    email: EmailStr
    password: str = Field(..., min_length=6)
    telefono: Optional[str] = None
    provincia: Optional[str] = None
    ubicacion: Optional[str] = None  # detalle: ciudad/corregimiento
    rol: str = "Comprador"  # "Comprador" | "Vendedor"
    genero: Optional[str] = None  # "masculino" | "femenino" | "otro"
    fecha_nacimiento: Optional[str] = None  # "YYYY-MM-DD"
    cedula: Optional[str] = None
    nombre_usuario: Optional[str] = None  # nombre del taller / usuario público
    ofrece_delivery: Optional[bool] = None

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------

@router.post("/login")
def login(req: LoginRequest):
    """
    Autentica al usuario y valida que su rol coincida con el modo solicitado.
    🔗 FLUTTER: POST /api/auth/login
    Body: { "email": "...", "password": "...", "modo": "Comprador" }
    """
    # Autenticar con Supabase
    try:
        response = supabase.auth.sign_in_with_password({
            "email": req.email,
            "password": req.password,
        })
        user = response.user
    except Exception as ex:
        msg = str(ex)
        if "Invalid login credentials" in msg:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Correo o contraseña incorrectos.")
        if "Email not confirmed" in msg:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Debes confirmar tu email antes de ingresar.")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error: {msg}")

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="No se pudo autenticar. Intenta de nuevo.")

    # Obtener perfil
    try:
        perfil_resp = supabase.table("perfiles").select("*").eq("user_id", user.id).single().execute()
        perfil = perfil_resp.data or {"nombre": req.email, "rol": "Comprador"}
    except Exception:
        perfil = {"nombre": req.email, "rol": "Comprador"}

    # Validar que el rol coincida con el modo
    rol_real = perfil.get("rol", "Comprador")
    if rol_real != req.modo:
        detalle = (
            "Esta cuenta es de vendedor. Usa el acceso de vendedor."
            if rol_real == "Vendedor"
            else "Esta cuenta es de comprador. Usa el acceso de comprador."
        )
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detalle)

    return {
        "success": True,
        "user_id": user.id,
        "email":   user.email,
        "modo":    req.modo,
        "perfil":  perfil,
    }


@router.post("/registro", status_code=status.HTTP_201_CREATED)
def registro(req: RegistroRequest):
    """
    Crea el usuario en Supabase Auth y su fila en 'perfiles'.
    🔗 FLUTTER: POST /api/auth/registro
    Body: { "nombre", "email", "password", "telefono", "provincia", "ubicacion", "rol" }
    Responde con la misma forma que /login para reusar la navegación post-login.
    """
    if req.rol not in ("Vendedor", "Comprador"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Rol inválido.")

    try:
        response = supabase.auth.sign_up({"email": req.email, "password": req.password})
        user = response.user
    except Exception as ex:
        msg = str(ex)
        if "already registered" in msg or "already been registered" in msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este correo ya tiene una cuenta activa. Inicia sesión.",
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error al crear la cuenta: {msg}")

    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No se pudo crear la cuenta. Intenta de nuevo.")

    perfil_data = {
        "user_id": user.id,
        "nombre": req.nombre.strip(),
        "email": req.email,
        "telefono": req.telefono.strip() if req.telefono else None,
        "provincia": req.provincia,
        "ubicacion": req.ubicacion.strip() if req.ubicacion else None,
        "rol": req.rol,
        "genero": req.genero,
        "fecha_nacimiento": req.fecha_nacimiento,
        "cedula": req.cedula.strip() if req.cedula else None,
        "nombre_usuario": req.nombre_usuario.strip() if req.nombre_usuario else None,
        "ofrece_delivery": req.ofrece_delivery,
    }

    try:
        supabase.table("perfiles").insert(perfil_data).execute()
    except Exception as ex:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Cuenta creada pero no se pudo guardar el perfil: {str(ex)}",
        )

    return {
        "success": True,
        "user_id": user.id,
        "email": user.email,
        "modo": req.rol,
        "perfil": perfil_data,
    }


@router.post("/logout")
def logout():
    """
    Cierra la sesión en Supabase.
    🔗 FLUTTER: POST /api/auth/logout
    """
    try:
        supabase.auth.sign_out()
        return {"success": True}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@router.get("/roles")
def obtener_roles():
    """
    Devuelve las opciones de rol disponibles para renderizar en Flutter.
    🔗 FLUTTER: GET /api/auth/roles
    """
    return {
        "roles": [
            {
                "id":       "Vendedor",
                "titulo":   "VENDEDOR",
                "icono":    "building-store",
                "descripcion": "Convierte lo que amas crear en una oportunidad. Publica tus productos, recibe pedidos y haz crecer tu taller en CraftHub.",
                "acciones": [
                    {"texto": "Iniciar sesion", "accion": "login_vendedor"},
                ],
            },
            {
                "id":       "Comprador",
                "titulo":   "COMPRADOR",
                "icono":    "shopping-bag",
                "descripcion": "Explora artesanias panamenas hechas con pasion. Descubre historias, productos unicos y compra cuando quieras.",
                "acciones": [
                    {"texto": "Explorar",      "accion": "explorar"},
                    {"texto": "Iniciar sesion","accion": "login_comprador"},
                ],
            },
        ]
    }