import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/models_chat.dart';
import 'avatar_contacto.dart';

/// Tarjeta de conversacion en el panel izquierdo.
class TarjetaConversacion extends StatelessWidget {
  final ConversacionModelo conversacion;
  final bool seleccionada;
  final VoidCallback alTap;

  const TarjetaConversacion({
    super.key,
    required this.conversacion,
    required this.seleccionada,
    required this.alTap,
  });

  String _formatearHora(BuildContext context, DateTime hora) {
    final diff = DateTime.now().difference(hora);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return tr(context, 'compartido.ayer');
    return '${diff.inDays} ${tr(context, 'compartido.dias_abrev')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: alTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada
              ? (isDark
                    ? CraftHubColors.vinoTinto.withValues(alpha: 0.25)
                    : CraftHubColors.vinoTintoSuave)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: seleccionada
              ? Border.all(
                  color: CraftHubColors.vinoTinto.withValues(alpha: 0.4),
                )
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarContacto(
                  nombre: conversacion.nombreContacto,
                  avatarUrl: conversacion.avatarUrl,
                  radio: 24,
                ),
                if (conversacion.enLinea)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: CraftHubColors.exito,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CraftHubColors.panel(isDark),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversacion.nombreContacto,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: CraftHubColors.textoPrincipal(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatearHora(context, conversacion.horaUltimo),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: conversacion.mensajesNoLeidos > 0
                              ? CraftHubColors.vinoTinto
                              : CraftHubColors.textoSecundario(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversacion.ultimoMensaje,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: CraftHubColors.textoSecundario(isDark),
                            fontWeight: conversacion.mensajesNoLeidos > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversacion.mensajesNoLeidos > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CraftHubColors.vinoTinto,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${conversacion.mensajesNoLeidos}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
