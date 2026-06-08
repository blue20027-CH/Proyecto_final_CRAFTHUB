from pydantic import BaseModel, Field, field_validator, EmailStr, model_validator
from typing import Optional, List
from datetime import datetime

class ProductoBase(BaseModel):
    nombre: str
    precio: float
    stock: int = 0
    categoria: str = "Artesania"
    descripcion: Optional[str] = None
    img: Optional[str] = None
    color: str = "#C4A882"

    @field_validator("precio", mode="before")
    @classmethod
    def limpiar_precio(cls, v):
        if isinstance(v, str):
            return float(v.replace("$", "").replace(",", "").strip())
        return float(v)

class ProductoCreate(ProductoBase):
    creador: str  # Nombre del vendedor

class ProductoResponse(ProductoBase):
    id: int
    creador: str
    ventas: int = 0

class NotificacionResponse(BaseModel):
    id: int
    user_id: str
    titulo: str
    mensaje: str
    leida: bool
    created_at: datetime
    
    
    

class RegistroUsuario(BaseModel):
    nombre: str = Field(..., min_length=1, description="Nombre completo obligatorio")
    email: EmailStr
    password: str = Field(..., min_length=6, description="La contraseña debe tener al menos 6 caracteres")
    confirm_password: str
    telefono: Optional[str] = None
    ubicacion: Optional[str] = None
    rol: str = Field(..., description="Debe ser 'Vendedor' o 'Comprador'")

    @model_validator(mode="after")
    def verificar_passwords_y_rol(self):
        # 1. Validar que las contraseñas coincidan
        if self.password != self.confirm_password:
            raise ValueError("Las contraseñas no coinciden.")
        
        # 2. Validar que el rol sea correcto
        if self.rol not in ["Vendedor", "Comprador"]:
            raise ValueError("Selecciona si eres comprador o vendedor (Rol inválido).")
            
        return self