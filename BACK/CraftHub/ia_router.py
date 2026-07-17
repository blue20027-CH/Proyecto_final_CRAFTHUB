import json
import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from supabase_client import supabase
from mistral_client import cliente_mistral, MODELO_TEXTO, MODELO_VISION
from ml_tonos import tono_recomendado

router = APIRouter(prefix="/api/ia", tags=["IA"])

# Identidad del asistente en el chat: participa como un contacto más en las
# conversaciones, con un autor_id fijo para distinguir sus mensajes.
BOT_ID = "00000000-0000-4000-8000-0000c7af41a0"
BOT_NOMBRE = "CraftHub IA"
BOT_ROL = "Asistente IA"

# Identidad de marca (del Manual de Identidad Corporativa de CraftHub): la IA
# la usa para que todo lo que escriba suene a la marca y responda bien a
# preguntas sobre quién es CraftHub.
IDENTIDAD_MARCA = """Identidad de la marca CraftHub:
- Eslogan: "Creatividad con propósito".
- Qué es: plataforma digital panameña de comercialización y distribución de productos artesanales y locales de las provincias y comarcas de Panamá.
- Misión: brindar a los artesanos de Panamá una plataforma digital accesible, innovadora y fácil de usar para promocionar, comercializar y posicionar sus productos, fortaleciendo su crecimiento económico y preservando la identidad cultural artesanal del país.
- Visión: ser la principal plataforma digital de comercialización artesanal en Panamá, impulsando el reconocimiento nacional e internacional del talento artesanal panameño.
- Valores: autenticidad, identidad cultural, innovación y compromiso social.
- Colores institucionales: vino (#821515, pasión por la creación y calidez artesanal), negro (solidez y elegancia), gris (equilibrio) y blanco (transparencia y claridad).
- El logo es un isotipo con las letras C y H unidas en un bloque: simboliza el "hub" donde convergen artesanos y compradores."""

# Cómo debe escribir la IA según la personalidad de marca que el vendedor
# eligió en "Personalizar mi marca" (perfiles.marca_personalidad).
TONOS_MARCA = {
    "Elegante":    "un tono sofisticado y exclusivo, con vocabulario refinado, dirigido a quienes valoran las piezas finas",
    "Amigable":    "un tono cercano, cálido y alegre, como si le hablaras a un amigo, con entusiasmo genuino",
    "Profesional": "un tono serio, claro y confiable, enfocado en la calidad y el detalle técnico del producto",
    "Cálido":      "un tono acogedor y emotivo, que resalte el cariño y la dedicación puestos en cada pieza",
    "Moderno":     "un tono fresco, directo y actual, con frases cortas y energía contemporánea",
    "Minimalista": "un tono sobrio y conciso, sin adornos innecesarios, dejando que el producto hable por sí solo",
    "Juvenil":     "un tono divertido, espontáneo y con chispa, que conecte con compradores jóvenes",
    "Tradicional": "un tono que honre las raíces, la historia y las técnicas heredadas de generación en generación",
    "Artesanal":   "un tono que celebre el trabajo hecho a mano, el proceso y la autenticidad de cada pieza única",
    "Exclusivo":   "un tono aspiracional que resalte la escasez y el carácter irrepetible de la pieza",
    "Premium":     "un tono de alta gama que enfatice materiales superiores, acabados impecables y prestigio",
}


class GenerarProductoRequest(BaseModel):
    borrador: str
    categoria: str = ""
    vendedor_nombre: str = ""


def _extraer_json(texto: str) -> dict:
    """El modelo a veces envuelve el JSON en ```json ... ``` — se limpia antes de parsear."""
    limpio = re.sub(r"^```(json)?|```$", "", texto.strip(), flags=re.MULTILINE).strip()
    return json.loads(limpio)


def _personalidad_de(vendedor_nombre: str) -> str:
    """Busca la personalidad de marca configurada por el vendedor (o '' si no tiene)."""
    if not vendedor_nombre:
        return ""
    try:
        resp = (
            supabase.table("perfiles")
            .select("marca_personalidad")
            .eq("nombre", vendedor_nombre)
            .limit(1)
            .execute()
        )
        if resp.data:
            return (resp.data[0].get("marca_personalidad") or "").strip()
    except Exception as ex:
        print(f"No se pudo leer la personalidad de marca de {vendedor_nombre}:", ex)
    return ""


@router.post("/generar-producto")
def generar_producto(req: GenerarProductoRequest):
    """
    Genera nombres creativos y una descripción atractiva para un producto
    artesanal, a partir de lo que el vendedor ya escribió (borrador), su
    categoría y la personalidad de marca configurada en su perfil.
    🔗 FLUTTER: POST /api/ia/generar-producto
    """
    if not req.borrador.strip():
        raise HTTPException(status_code=400, detail="Escribe algo sobre el producto primero (aunque sea el nombre).")

    personalidad = _personalidad_de(req.vendedor_nombre)
    if personalidad not in TONOS_MARCA:
        # Sin personalidad configurada: el componente de ML recomienda el tono
        # que mejor ha funcionado para esta categoría según el feedback de
        # otros vendedores (ml_tonos.py).
        personalidad = tono_recomendado(req.categoria)
    instruccion_tono = ""
    if personalidad in TONOS_MARCA:
        instruccion_tono = (
            f"\nLa marca de este artesano tiene personalidad \"{personalidad}\": "
            f"escribe todo con {TONOS_MARCA[personalidad]}."
        )

    prompt = f"""Eres el asistente de marketing de CraftHub para sus artesanos.

{IDENTIDAD_MARCA}

Un vendedor está creando esta publicación:
- Categoría: {req.categoria or "sin especificar"}
- Lo que escribió el vendedor: "{req.borrador.strip()}"
{instruccion_tono}
Genera:
1. Cinco nombres creativos y cortos para el producto (máximo 5 palabras cada uno).
2. Una descripción atractiva de 2 a 3 frases, auténtica, que resalte el origen panameño y el trabajo artesanal, sin inventar materiales o detalles que el vendedor no mencionó.

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
            "personalidad": personalidad,
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="La IA respondió en un formato inesperado. Intenta de nuevo.")
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error generando con IA: {ex}")


# ---------------------------------------------------------------------------
# CHATBOT DE SOPORTE (aparece en el chat de todos los usuarios)
# ---------------------------------------------------------------------------

PROMPT_SOPORTE = """Eres "CraftHub IA", el asistente oficial de CraftHub, un marketplace panameño de artesanías donde artesanos (vendedores) venden sus piezas a compradores.

""" + IDENTIDAD_MARCA + """

Lo que sabes de la plataforma:
- COMPRAR: el comprador explora productos en el inicio, abre un producto para ver su detalle, y puede "Comprar ahora" o "Añadir al carrito". El pago se hace en el checkout.
- MÉTODOS DE PAGO: tarjeta de crédito/débito (Visa, Mastercard, Amex), transferencia bancaria (Banistmo, Banco Nacional, BAC Credomatic, Global Bank, Caja de Ahorros), Yappy, PayPal y Banistmo. Para pagar con Yappy/PayPal/Banistmo solo se ingresa el teléfono o correo asociado a esa billetera en el checkout (no hay códigos QR). También se pueden guardar tarjetas en "Mi perfil > Métodos de pago" (protegido con contraseña).
- ENVÍOS: el costo de envío se calcula según la distancia entre la provincia del artesano y la del comprador. Los pedidos se ven en "Historial de pedidos" del perfil.
- FAVORITOS: se pueden marcar productos y artesanos como favoritos con el corazón.
- CHAT: compradores y vendedores pueden chatear entre sí, compartir imágenes y publicaciones de productos.
- VENDER: el vendedor sube productos desde "Inventario" con el botón "Nuevo producto" (nombre, precio, stock, categoría, foto y descripción). Puede editar productos existentes con el lápiz. Puede usar el botón "Generar con IA" para que le sugiera nombres y descripciones.
- MARCA: el vendedor puede elegir la personalidad de su marca (Elegante, Amigable, etc.) en "Editar perfil", y la IA usará ese tono en sus textos.
- PEDIDOS DEL VENDEDOR: se gestionan en "Órdenes" (cambiar estado: pendiente, aceptada, enviado, completada) y se ven en el mapa de entregas.
- PERFIL: foto, portada, descripción, provincia y teléfono se cambian en "Editar perfil" (clic en el avatar).
- EVENTOS Y TUTORIALES: hay calendario de eventos artesanales y sección de tutoriales en video.

Reglas:
- Responde SIEMPRE en el idioma en el que te escriba el usuario (español o inglés).
- Sé breve, cálido y directo (2-4 frases máximo, usa listas solo si ayudan).
- Escribe en TEXTO PLANO: nada de Markdown, asteriscos, negritas ni encabezados (el chat no los muestra formateados). Los emojis sí están bien.
- Si no sabes algo o es un problema de cuenta/pago que no puedes resolver, di honestamente que no puedes ayudar con eso y recomienda escribir a soporte@crafthub.com.
- Nunca inventes funciones que no están en la lista.
- El usuario con el que hablas es {rol}."""


class AbrirChatbotRequest(BaseModel):
    usuario_id: str
    usuario_nombre: str


class ChatbotMensajeRequest(BaseModel):
    conversacion_id: str
    usuario_id: str
    usuario_nombre: str = ""
    mensaje: str


def _modo_de(usuario_id: str) -> str:
    try:
        resp = supabase.table("perfiles").select("modo, rol").eq("user_id", usuario_id).limit(1).execute()
        if resp.data:
            return (resp.data[0].get("modo") or resp.data[0].get("rol") or "comprador").strip().lower()
    except Exception:
        pass
    return "comprador"


@router.post("/chatbot/abrir")
def abrir_chatbot(req: AbrirChatbotRequest):
    """
    Garantiza que el usuario tenga su conversación con CraftHub IA (la crea
    con un mensaje de bienvenida si no existe) y la devuelve.
    🔗 FLUTTER: POST /api/ia/chatbot/abrir
    """
    try:
        propias = (
            supabase.table("conversaciones")
            .select("*")
            .or_(f"participante_1_id.eq.{req.usuario_id},participante_2_id.eq.{req.usuario_id}")
            .execute()
            .data
            or []
        )
        for conv in propias:
            nombres = {conv.get("participante_1_nombre"), conv.get("participante_2_nombre")}
            if BOT_NOMBRE in nombres:
                return {"conversacion_id": str(conv["id"]), "creada": False}

        nueva = supabase.table("conversaciones").insert({
            "participante_1_id": req.usuario_id,
            "participante_1_nombre": req.usuario_nombre,
            "participante_2_id": None,
            "participante_2_nombre": BOT_NOMBRE,
            "participante_2_rol": BOT_ROL,
            "ultimo_mensaje": "",
        }).execute()
        if not nueva.data:
            raise HTTPException(status_code=400, detail="No se pudo crear el chat con la IA.")
        conv_id = nueva.data[0]["id"]

        bienvenida = (
            "¡Hola! 👋 Soy CraftHub IA, tu asistente. Puedo ayudarte con dudas "
            "sobre cómo comprar, pagar, vender tus artesanías o usar la app. "
            "¿En qué te ayudo hoy?"
        )
        msg = supabase.table("mensajes").insert({
            "conversacion_id": conv_id,
            "autor_id": BOT_ID,
            "autor_nombre": BOT_NOMBRE,
            "contenido": bienvenida,
            "tipo": "texto",
            "leido": False,
        }).execute()
        if msg.data:
            supabase.table("conversaciones").update({
                "ultimo_mensaje": bienvenida,
                "ultimo_mensaje_hora": msg.data[0]["created_at"],
            }).eq("id", conv_id).execute()

        return {"conversacion_id": str(conv_id), "creada": True}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error abriendo el chat con la IA: {ex}")


@router.post("/chatbot/mensaje")
def chatbot_mensaje(req: ChatbotMensajeRequest):
    """
    Recibe un mensaje del usuario para CraftHub IA: lo guarda, genera la
    respuesta con Mistral usando el historial reciente, la guarda y la
    devuelve.
    🔗 FLUTTER: POST /api/ia/chatbot/mensaje
    """
    if not req.mensaje.strip():
        raise HTTPException(status_code=400, detail="El mensaje no puede estar vacío.")
    try:
        guardado = supabase.table("mensajes").insert({
            "conversacion_id": req.conversacion_id,
            "autor_id": req.usuario_id,
            "autor_nombre": req.usuario_nombre,
            "contenido": req.mensaje.strip(),
            "tipo": "texto",
            "leido": True,
        }).execute()
        if not guardado.data:
            raise HTTPException(status_code=400, detail="No se pudo guardar tu mensaje.")

        historial = (
            supabase.table("mensajes")
            .select("autor_id, contenido")
            .eq("conversacion_id", req.conversacion_id)
            .order("created_at", desc=True)
            .limit(12)
            .execute()
            .data
            or []
        )
        historial.reverse()

        modo = _modo_de(req.usuario_id)
        rol_texto = "un vendedor/artesano de la plataforma" if modo == "vendedor" else "un comprador de la plataforma"
        mensajes_llm = [{"role": "system", "content": PROMPT_SOPORTE.format(rol=rol_texto)}]
        for m in historial:
            es_bot = m.get("autor_id") == BOT_ID
            mensajes_llm.append({
                "role": "assistant" if es_bot else "user",
                "content": m.get("contenido") or "",
            })

        cliente = cliente_mistral()
        respuesta = cliente.chat.complete(
            model=MODELO_TEXTO,
            messages=mensajes_llm,
            temperature=0.4,
        )
        texto_bot = (respuesta.choices[0].message.content or "").strip()
        # El chat muestra texto plano: se limpia cualquier Markdown que el
        # modelo insista en usar (negritas, encabezados) para que no se vean
        # los asteriscos literales en la burbuja.
        texto_bot = re.sub(r"\*\*(.+?)\*\*", r"\1", texto_bot)
        texto_bot = re.sub(r"(?m)^#+\s*", "", texto_bot)
        if not texto_bot:
            texto_bot = "Perdona, no pude generar una respuesta. ¿Puedes intentarlo de nuevo?"

        msg_bot = supabase.table("mensajes").insert({
            "conversacion_id": req.conversacion_id,
            "autor_id": BOT_ID,
            "autor_nombre": BOT_NOMBRE,
            "contenido": texto_bot,
            "tipo": "texto",
            "leido": False,
        }).execute()
        if msg_bot.data:
            supabase.table("conversaciones").update({
                "ultimo_mensaje": texto_bot,
                "ultimo_mensaje_hora": msg_bot.data[0]["created_at"],
            }).eq("id", req.conversacion_id).execute()

        return {"respuesta": texto_bot}
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error en el chatbot: {ex}")


# ---------------------------------------------------------------------------
# ANÁLISIS DE IMAGEN DE PRODUCTO (Pixtral)
# ---------------------------------------------------------------------------

class AnalizarImagenRequest(BaseModel):
    imagen_url: str


@router.post("/analizar-imagen")
def analizar_imagen(req: AnalizarImagenRequest):
    """
    Analiza la foto de un producto con Pixtral: puntúa su calidad comercial
    y da recomendaciones concretas para mejorarla.
    🔗 FLUTTER: POST /api/ia/analizar-imagen
    """
    if not req.imagen_url.strip().startswith("http"):
        raise HTTPException(status_code=400, detail="Sube primero una imagen del producto.")

    prompt = """Eres un fotógrafo de producto que asesora a artesanos panameños en CraftHub.
Analiza esta foto de producto considerando: iluminación, enfoque, fondo, composición, visibilidad del producto y resolución.

Responde ÚNICAMENTE con este JSON, sin texto adicional ni markdown:
{"puntuacion": 4.2, "resumen": "una frase con el veredicto general", "recomendaciones": ["consejo concreto 1", "consejo concreto 2", "consejo concreto 3"]}

La puntuación va de 1.0 a 5.0. Da entre 2 y 4 recomendaciones accionables en español. Si la foto ya es excelente, dilo y da como máximo un consejo menor."""

    try:
        cliente = cliente_mistral()
        respuesta = cliente.chat.complete(
            model=MODELO_VISION,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": req.imagen_url.strip()},
                ],
            }],
            temperature=0.3,
        )
        datos = _extraer_json(respuesta.choices[0].message.content)
        puntuacion = float(datos.get("puntuacion", 0) or 0)
        return {
            "puntuacion": max(1.0, min(5.0, puntuacion)),
            "resumen": (datos.get("resumen") or "").strip(),
            "recomendaciones": [r for r in (datos.get("recomendaciones") or []) if r][:4],
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="La IA respondió en un formato inesperado. Intenta de nuevo.")
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error analizando la imagen: {ex}")


# ---------------------------------------------------------------------------
# FEEDBACK DE SUGERENCIAS (datos de entrenamiento del ML)
# ---------------------------------------------------------------------------

class FeedbackNombresRequest(BaseModel):
    vendedor_nombre: str
    categoria: str = ""
    personalidad: str = ""
    aceptado: str
    rechazados: list[str] = []


@router.post("/feedback-nombres")
def feedback_nombres(req: FeedbackNombresRequest):
    """
    Registra qué nombre sugerido aceptó el vendedor (y cuáles rechazó).
    Estos datos alimentan el componente de ML que aprende el tono más
    efectivo por categoría (ml_tonos.py).
    🔗 FLUTTER: POST /api/ia/feedback-nombres
    """
    try:
        filas = [{
            "vendedor_nombre": req.vendedor_nombre,
            "categoria": req.categoria,
            "personalidad": req.personalidad,
            "sugerencia": req.aceptado,
            "aceptada": True,
        }]
        filas += [{
            "vendedor_nombre": req.vendedor_nombre,
            "categoria": req.categoria,
            "personalidad": req.personalidad,
            "sugerencia": r,
            "aceptada": False,
        } for r in req.rechazados if r]
        supabase.table("ia_sugerencias").insert(filas).execute()
        return {"success": True}
    except Exception as ex:
        # No es crítico: si la tabla no existe aún, el flujo principal sigue.
        print("No se pudo registrar el feedback de nombres:", ex)
        return {"success": False}


# ---------------------------------------------------------------------------
# ANÁLISIS DEL PERFIL DEL VENDEDOR
# ---------------------------------------------------------------------------

@router.get("/analizar-perfil/{user_id}")
def analizar_perfil(user_id: str):
    """
    Evalúa qué tan completo está el perfil del vendedor (puntuación 0-100)
    y genera recomendaciones personalizadas con IA para mejorarlo.
    🔗 FLUTTER: GET /api/ia/analizar-perfil/{user_id}
    """
    try:
        resp = supabase.table("perfiles").select("*").eq("user_id", user_id).limit(1).execute()
        if not resp.data:
            raise HTTPException(status_code=404, detail="Perfil no encontrado.")
        perfil = resp.data[0]
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Error leyendo el perfil: {ex}")

    nombre = perfil.get("nombre") or ""
    try:
        prods = supabase.table("productos").select("id", count="exact").eq("creador", nombre).execute()
        total_productos = prods.count or 0
    except Exception:
        total_productos = 0

    # Puntuación determinista por completitud (cada pieza suma su peso).
    criterios = {
        "foto":         (15, bool(perfil.get("foto"))),
        "portada":      (15, bool(perfil.get("foto_portada"))),
        "descripcion":  (20, len((perfil.get("descripcion") or "").strip()) >= 30),
        "provincia":    (10, bool(perfil.get("provincia"))),
        "categoria":    (10, bool(perfil.get("categoria"))),
        "personalidad": (10, bool(perfil.get("marca_personalidad"))),
        "productos":    (20, total_productos >= 5),
    }
    puntuacion = sum(peso for peso, cumple in criterios.values() if cumple)
    faltantes = [clave for clave, (_, cumple) in criterios.items() if not cumple]

    # La IA redacta las recomendaciones con el tono de la marca; si falla,
    # se devuelve una lista básica igual de útil.
    recomendaciones = []
    if faltantes:
        detalle = {
            "foto": "no tiene foto de perfil",
            "portada": "no tiene foto de portada",
            "descripcion": "su descripción/historia está vacía o es muy corta",
            "provincia": "no ha indicado su provincia",
            "categoria": "no ha elegido su categoría principal",
            "personalidad": "no ha configurado la personalidad de su marca",
            "productos": f"solo tiene {total_productos} producto(s) publicados (lo ideal es 5 o más)",
        }
        resumen_faltantes = "; ".join(detalle[f] for f in faltantes)
        prompt = f"""Eres el asistente de CraftHub que ayuda a artesanos panameños a mejorar su perfil de vendedor.

El perfil de {nombre or "este artesano"} está al {puntuacion}%. Le falta: {resumen_faltantes}.

Escribe una recomendación breve, cálida y accionable por cada punto faltante (máximo una frase cada una, sin Markdown).

Responde ÚNICAMENTE con este JSON, sin texto adicional:
{{"recomendaciones": ["...", "..."]}}"""
        try:
            cliente = cliente_mistral()
            respuesta = cliente.chat.complete(
                model=MODELO_TEXTO,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.5,
            )
            datos = _extraer_json(respuesta.choices[0].message.content)
            recomendaciones = [r for r in (datos.get("recomendaciones") or []) if r][:6]
        except Exception as ex:
            print("IA no disponible para recomendaciones de perfil:", ex)
        if not recomendaciones:
            basicas = {
                "foto": "Agrega una foto de perfil para que los compradores te reconozcan.",
                "portada": "Sube una portada que muestre tu taller o tus piezas.",
                "descripcion": "Cuenta tu historia como artesano en la descripción.",
                "provincia": "Indica tu provincia para aparecer en el mapa.",
                "categoria": "Elige tu categoría principal de artesanía.",
                "personalidad": "Configura la personalidad de tu marca para que la IA escriba con tu estilo.",
                "productos": "Publica al menos 5 productos para dar más confianza.",
            }
            recomendaciones = [basicas[f] for f in faltantes]

    return {
        "puntuacion": puntuacion,
        "total_productos": total_productos,
        "recomendaciones": recomendaciones,
    }
