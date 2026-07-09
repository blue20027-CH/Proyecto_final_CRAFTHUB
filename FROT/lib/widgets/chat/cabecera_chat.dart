import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import 'avatar_contacto.dart';

class CabeceraChat extends StatelessWidget {
  final ConversacionModelo conversacion;
  const CabeceraChat({super.key, required this.conversacion});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(isDark),
        border: Border(bottom: BorderSide(color: CraftHubColors.borde(isDark))),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              AvatarContacto(
                nombre: conversacion.nombreContacto,
                avatarUrl: conversacion.avatarUrl,
                radio: 22,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversacion.nombreContacto,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                ),
                Text(
                  conversacion.rolContacto,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: CraftHubColors.textoSecundario(isDark),
                  ),
                ),
                if (conversacion.enLinea)
                  const Text(
                    'En linea',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: CraftHubColors.exito,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: 'Mas opciones',
            child: InkWell(
              onTap: () => _mostrarOpciones(context, isDark),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? CraftHubColors.panelOscuro2
                      : CraftHubColors.fondoClaro,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: CraftHubColors.textoSecundario(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarOpciones(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CraftHubColors.panel(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Opciones',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: CraftHubColors.textoPrincipal(isDark),
          ),
        ),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: CraftHubColors.textoSecundario(isDark),
                  size: 20,
                ),
                title: Text(
                  'Ver perfil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.notifications_off_outlined,
                  color: CraftHubColors.textoSecundario(isDark),
                  size: 20,
                ),
                title: Text(
                  'Silenciar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.block,
                  color: CraftHubColors.error,
                  size: 20,
                ),
                title: const Text(
                  'Bloquear',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: CraftHubColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
