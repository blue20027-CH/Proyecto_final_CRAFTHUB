import os
import sys
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from supabase_client import supabase
from auth_controller import login_usuario_supabase
from pedidos_router import router as pedidos_router
from notificaciones_router import router as notificaciones_router
from perfil_router import router as perfil_router
from auth_router import router as auth_router
from productos_router import router as productos_router
from vendedores_router import router as vendedores_router
from artesanos_router import router as artesanos_router
from carrito_router import router as carrito_router
from tutoriales_router import router as tutoriales_router
from eventos_router import router as eventos_router
from preferencias_router import router as preferencias_router
from anuncios_router import router as anuncios_router
from proveedores_router import router as proveedores_router
from chat_router import router as chat_router
from tarjetas_router import router as tarjetas_router
from ia_router import router as ia_router


app = FastAPI(
    title="CraftHub API",
    description="Backend para la plataforma de artesanías y cultura panameña",
    version="1.0.0"
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
# En dev siempre permitimos localhost. En producción, seteá la env var
# FRONTEND_URL con el dominio del frontend (p. ej. https://crafthub.vercel.app)
# para agregarlo a los orígenes permitidos.
_frontend_url = os.environ.get("FRONTEND_URL", "").strip().rstrip("/")

_origenes_cors = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:5959",
    "http://localhost:8080",
    "http://127.0.0.1:5959",
    "http://127.0.0.1:8080",
]
if _frontend_url:
    _origenes_cors.append(_frontend_url)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origenes_cors,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# ROUTERS
# ---------------------------------------------------------------------------
app.include_router(pedidos_router)
app.include_router(notificaciones_router)
app.include_router(perfil_router)
app.include_router(auth_router)
app.include_router(productos_router)
app.include_router(vendedores_router)
app.include_router(artesanos_router)
app.include_router(carrito_router)
app.include_router(tutoriales_router)
app.include_router(eventos_router)
app.include_router(preferencias_router)
app.include_router(anuncios_router)
app.include_router(proveedores_router)
app.include_router(chat_router)
app.include_router(tarjetas_router)
app.include_router(ia_router)

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
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
