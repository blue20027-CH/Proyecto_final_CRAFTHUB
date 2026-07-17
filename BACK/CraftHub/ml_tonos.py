"""
ml_tonos.py
Componente de Machine Learning de CraftHub IA: aprende de las sugerencias de
nombres que los vendedores aceptan o rechazan (tabla ia_sugerencias) para
recomendar automáticamente el tono/personalidad de marca más adecuado según
la categoría de artesanía.

Con pocos datos usa frecuencias de aceptación por categoría; cuando hay
suficientes ejemplos entrena un clasificador Naive Bayes (scikit-learn) sobre
el texto de las sugerencias aceptadas para predecir la personalidad que mejor
encaja con cada categoría.
"""

from collections import Counter
from supabase_client import supabase

# Mínimo de sugerencias aceptadas para intentar entrenar el clasificador de
# texto; por debajo de esto se usa el conteo simple de aceptación.
MINIMO_PARA_CLASIFICADOR = 20


def _cargar_feedback():
    try:
        resp = (
            supabase.table("ia_sugerencias")
            .select("categoria, personalidad, sugerencia, aceptada")
            .execute()
        )
        return resp.data or []
    except Exception:
        return []


def _por_frecuencia(feedback, categoria: str) -> str:
    """Personalidad con mejor tasa de aceptación dentro de la categoría."""
    aceptadas = Counter()
    mostradas = Counter()
    for f in feedback:
        if (f.get("categoria") or "") != categoria or not f.get("personalidad"):
            continue
        mostradas[f["personalidad"]] += 1
        if f.get("aceptada"):
            aceptadas[f["personalidad"]] += 1
    if not aceptadas:
        return ""
    mejor = max(aceptadas, key=lambda p: aceptadas[p] / max(1, mostradas[p]))
    return mejor


def _por_clasificador(feedback, categoria: str) -> str:
    """
    Clasificador Naive Bayes: aprende qué personalidad producen los nombres
    que los vendedores SÍ aceptaron, y predice la más probable para la
    categoría dada usando los nombres aceptados de esa categoría.
    """
    try:
        from sklearn.feature_extraction.text import CountVectorizer
        from sklearn.naive_bayes import MultinomialNB

        textos, etiquetas = [], []
        for f in feedback:
            if f.get("aceptada") and f.get("personalidad") and f.get("sugerencia"):
                textos.append(f"{f.get('categoria') or ''} {f['sugerencia']}")
                etiquetas.append(f["personalidad"])
        if len(textos) < MINIMO_PARA_CLASIFICADOR or len(set(etiquetas)) < 2:
            return ""

        vectorizador = CountVectorizer()
        X = vectorizador.fit_transform(textos)
        modelo = MultinomialNB()
        modelo.fit(X, etiquetas)

        prediccion = modelo.predict(vectorizador.transform([categoria]))
        return str(prediccion[0])
    except Exception:
        return ""


def tono_recomendado(categoria: str) -> str:
    """
    Devuelve la personalidad de marca recomendada para una categoría de
    artesanía según lo aprendido del feedback, o '' si aún no hay datos.
    """
    if not categoria:
        return ""
    feedback = _cargar_feedback()
    if not feedback:
        return ""
    return _por_clasificador(feedback, categoria) or _por_frecuencia(feedback, categoria)
