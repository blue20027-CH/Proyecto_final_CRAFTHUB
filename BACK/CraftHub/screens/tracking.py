from fastapi import APIRouter, HTTPException, status
from supabase_client import supabase

router = APIRouter(prefix="/api/pedidos", tags=["Pedidos"])


# ---------------------------------------------------------------------------
# GET /api/pedidos/{user_id}
# 🔗 FLUTTER: lib/services/pedidos_service.dart → cargarPedidos(userId)
# ---------------------------------------------------------------------------
@router.get("/{user_id}")
def obtener_pedidos(user_id: str):
    """
    Retorna todos los pedidos del comprador ordenados por fecha descendente.
    """
    try:
        resultado = (
            supabase.table("pedidos")
            .select("*")
            .eq("comprador_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return {
            "status": "ok",
            "pedidos": resultado.data or []
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ---------------------------------------------------------------------------
# GET /api/pedidos/{user_id}/{pedido_id}
# 🔗 FLUTTER: lib/services/pedidos_service.dart → cargarDetallePedido(pedidoId)
# ---------------------------------------------------------------------------
@router.get("/{user_id}/{pedido_id}")
def obtener_detalle_pedido(user_id: str, pedido_id: str):
    """
    Retorna el detalle completo de un pedido específico incluyendo
    productos, estado, datos de envío y tracking.
    """
    try:
        resultado = (
            supabase.table("pedidos")
            .select("*")
            .eq("id", pedido_id)
            .eq("comprador_id", user_id)
            .single()
            .execute()
        )

        if not resultado.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pedido no encontrado"
            )

        pedido = resultado.data

        # Calcular progreso según estado para el mapa de tracking
        estado = (pedido.get("estado") or "pendiente").lower()
        progreso_map = {
            "pendiente":   0.12,
            "en proceso":  0.40,
            "enviado":     0.68,
            "entregado":   1.0,
        }
        progreso = progreso_map.get(estado, 0.12)

        return {
            "status": "ok",
            "pedido": pedido,
            "tracking": {
                "estado_key": estado,
                "progreso":   progreso,          # 0.0 → 1.0 para la barra del mapa
                "estado_label": {
                    "pendiente":  "Preparando",
                    "en proceso": "Procesando",
                    "enviado":    "En camino",
                    "entregado":  "Entregado",
                }.get(estado, estado.capitalize()),
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
