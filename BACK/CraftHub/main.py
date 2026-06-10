from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase_client import supabase

app = FastAPI(title="CraftHub API", version="1.0.0")

# ─── CORS (permite conexión desde Flutter Web o cualquier origen) ────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # ⚠️ En producción reemplaza "*" por tu dominio
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── MODELOS ─────────────────────────────────────────────────────────────────
class CredencialesLogin(BaseModel):
    email: str
    password: str

# ─── ENDPOINTS ───────────────────────────────────────────────────────────────

@app.get("/")
def raiz():
    return {"mensaje": "CraftHub API activa ✅"}


@app.post("/auth/login")
def login(credenciales: CredencialesLogin):
    """
    Autentica al usuario con Supabase Auth y devuelve su perfil.

    🔗 FLUTTER: conectar en lib/services/auth_service.dart
         POST http://<tu-ip>:8000/auth/login
         Body: { "email": "...", "password": "..." }
    """
    try:
        # Paso 1: Autenticar en Supabase Auth
        respuesta_auth = supabase.auth.sign_in_with_password({
            "email": credenciales.email,
            "password": credenciales.password
        })

        usuario = respuesta_auth.user
        sesion  = respuesta_auth.session

        if not usuario:
            raise HTTPException(status_code=401, detail="Credenciales inválidas")

        # Paso 2: Obtener perfil de la tabla pública
        resultado_perfil = (
            supabase.table("perfiles")
            .select("*")
            .eq("user_id", usuario.id)
            .single()
            .execute()
        )

        perfil = resultado_perfil.data

        return {
            "ok": True,
            "access_token": sesion.access_token,   # 🔗 Flutter: guarda este token
            "token_type": "bearer",
            "usuario": {
                "id":    usuario.id,
                "email": usuario.email,
            },
            "perfil": perfil   # contiene rol, nombre, foto, etc.
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
