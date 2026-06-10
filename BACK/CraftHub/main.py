import os
import sys
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from supabase_client import supabase
from auth_controller import login_usuario_supabase
from pedidos_router import router as pedidos_router

app = FastAPI(
    title="CraftHub API",
    description="Backend para la plataforma de artesanías y cultura panameña",
    version="1.0.0"
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # ⚠️ En producción reemplaza "*" por tu dominio
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# ROUTERS
# ---------------------------------------------------------------------------
app.include_router(pedidos_router)

# ---------------------------------------------------------------------------
# MODELOS
# ---------------------------------------------------------------------------
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------
@app.get("/")
def raiz():
    return {
        "status": "online",
        "proyecto": "CraftHub API Backend",
        "mensaje": "Servidor corriendo exitosamente."
    }


@app.post("/api/auth/login")
async def login(credenciales: LoginRequest):
    """
    Autentica al usuario con Supabase Auth y devuelve su perfil.
    🔗 FLUTTER: lib/services/auth_service.dart
         POST http://<tu-ip>:8000/api/auth/login
         Body: { "email": "...", "password": "..." }
    """
    resultado = login_usuario_supabase(credenciales.email, credenciales.password)

    if resultado["status"] == "error":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Error de autenticación: {resultado['message']}"
        )

    return resultado


# ---------------------------------------------------------------------------
# INICIO
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    print("\n[CraftHub] Iniciando servidor backend...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
