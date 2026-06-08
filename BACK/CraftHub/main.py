import os
import sys
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import Optional

# Aseguramos que Python encuentre los módulos locales en el mismo directorio
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Importamos la función lógica que interactúa con Supabase
from auth_controller import login_usuario_supabase 

# Inicializamos FastAPI con metadatos del proyecto CraftHub
app = FastAPI(
    title="CraftHub API",
    description="Backend para la plataforma de artesanías y cultura panameña",
    version="1.0.0"
)

# ---------------------------------------------------------------------------
# CONFIGURACIÓN DE CORS (Cross-Origin Resource Sharing)
# ---------------------------------------------------------------------------
# Esto permite que tu aplicación de Flutter (corriendo en un emulador, celular
# físico o como app de escritorio Windows/macOS) pueda comunicarse con este backend.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción se cambia por las IPs/Dominios específicos
    allow_credentials=True,
    allow_methods=["*"],  # Permite GET, POST, PUT, DELETE, etc.
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# MODELOS DE CONTROL DE DATOS (Pydantic)
# ---------------------------------------------------------------------------
class LoginRequest(BaseModel):
    email: EmailStr  # Valida automáticamente que el formato del correo sea real y válido
    password: str

# ---------------------------------------------------------------------------
# ENDPOINTS / RUTAS DE LA API
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    """Ruta base para verificar si el servidor está encendido correctamente."""
    return {
        "status": "online",
        "proyecto": "CraftHub API Backend",
        "mensaje": "Servidor corriendo exitosamente."
    }

@app.post("/api/auth/login")
async def login(credentials: LoginRequest):
    """
    Endpoint principal para la autenticación desde Flutter.
    Recibe el JSON con email y password, ejecuta la lógica en Supabase 
    y retorna los datos del usuario junto a su respectivo perfil.
    """
    # Ejecutamos la lógica real conectada a Supabase que extrajimos de tus pruebas
    resultado = login_usuario_supabase(credentials.email, credentials.password)
    
    # Si Supabase devolvió un error (clave incorrecta, usuario no existe, etc.)
    if resultado["status"] == "error":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Error de autenticación: {resultado['message']}"
        )
        
    # Si todo sale bien, retorna a Flutter el estado, datos de usuario y el perfil completo
    return resultado

# ---------------------------------------------------------------------------
# INICIO DEL SERVIDOR
# ---------------------------------------------------------------------------
# Al ejecutar 'python main.py' desde tu terminal, el servidor se levantará automáticamente
if __name__ == "__main__":
    import uvicorn
    print("\n[CraftHub] Iniciando servidor backend...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)