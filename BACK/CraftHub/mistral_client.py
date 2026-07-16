import os
from dotenv import load_dotenv
from mistralai.client import Mistral

load_dotenv()

MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY", "")

MODELO_TEXTO = "mistral-small-latest"
MODELO_VISION = "pixtral-12b-latest"


def cliente_mistral() -> Mistral:
    """Cliente de Mistral para texto (nombres, descripciones, chatbot) y visión (Pixtral)."""
    if not MISTRAL_API_KEY:
        raise RuntimeError(
            "Falta MISTRAL_API_KEY en el archivo .env — consigue una key gratis en "
            "https://console.mistral.ai y pégala ahí."
        )
    return Mistral(api_key=MISTRAL_API_KEY)
