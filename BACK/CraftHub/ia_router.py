import json
import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from mistral_client import cliente_mistral, MODELO_TEXTO

router = APIRouter(prefix="/api/ia", tags=["IA"])


class GenerarProductoRequest(BaseModel):
    borrador: str
    categoria: str = ""


def _extraer_json(texto: str) -> dict:
    """El modelo a veces envuelve el JSON en ```json ... ``` — se limpia antes de parsear."""
    limpio = re.sub(r"^```(json)?|```$", "", texto.strip(), flags=re.MULTILINE).strip()
    return json.loads(limpio)


@router.post("/generar-producto")
def generar_producto(req: GenerarProductoRequest):
    """
    Genera nombres creativos y una descripción atractiva para un producto
    artesanal, a partir de lo que el vendedor ya escribió (borrador) y su
    categoría.
    🔗 FLUTTER: POST /api/ia/generar-producto
    """
    if not req.borrador.strip():
        raise HTTPException(status_code=400, detail="Escribe algo sobre el producto primero (aunque sea el nombre).")

    prompt = f"""Eres un asistente de marketing para artesanos panameños que venden en CraftHub, un marketplace de artesanías de Panamá.

Un vendedor está creando esta publicación:
- Categoría: {req.categoria or "sin especificar"}
- Lo que escribió el vendedor: "{req.borrador.strip()}"

Genera:
1. Cinco nombres creativos y cortos para el producto (máximo 5 palabras cada uno).
2. Una descripción atractiva de 2 a 3 frases, cálida y auténtica, que resalte el origen panameño y el trabajo artesanal, sin inventar materiales o detalles que el vendedor no mencionó.

Responde ÚNICAMENTE con este JSON, sin texto adicional ni markdown:
{{"nombres": ["...", "...", "...", "...", "..."], "descripcion": "..."}}"""

    try:
        cliente = cliente_mistral()
        respuesta = cliente.chat.complete(
            model=MODELO_TEXTO,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )
        contenido = respuesta.choices[0].message.content
        datos = _extraer_json(contenido)
        return {
            "nombres": datos.get("nombres", [])[:5],
            "descripcion": datos.get("descripcion", ""),
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="La IA respondió en un formato inesperado. Intenta de nuevo.")
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error generando con IA: {ex}")
