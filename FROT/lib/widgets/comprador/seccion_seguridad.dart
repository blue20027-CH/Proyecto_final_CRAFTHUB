// lib/widgets/comprador/seccion_seguridad.dart
// Sección "Seguridad y privacidad" de Mi perfil/Configuración: filas de
// navegación hacia el cambio de contraseña (modal) y un resumen honesto de
// la actividad de la cuenta. Cada acción sensible de la cuenta (tarjetas,
// contraseña) exige verificar la contraseña real — ver
// dialogo_confirmar_password.dart y seccion_cambiar_password.dart.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'seccion_cambiar_password.dart';
import 'tarjeta_seccion.dart';

class SeccionSeguridad extends StatelessWidget {
  final String email;
  final bool esOscuro;
  const SeccionSeguridad({super.key, required this.email, required this.esOscuro});

  void _mostrarActividadCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Actividad de la cuenta', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Sesión iniciada como $email.\n\n'
          'El seguimiento detallado de dispositivos y sesiones activas todavía '
          'no está disponible en CraftHub. Mientras tanto, cualquier cambio de '
          'contraseña o de tarjetas guardadas exige verificar tu contraseña actual.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccion(
      esOscuro: esOscuro,
      icono: Icons.shield_outlined,
      titulo: 'Seguridad y privacidad',
      subtitulo: 'Administra la seguridad de tu cuenta.',
      colapsable: true,
      child: Column(
        children: [
          _FilaSeguridad(
            esOscuro: esOscuro,
            icono: Icons.lock_outline_rounded,
            titulo: 'Cambiar contraseña',
            subtitulo: 'Actualiza tu contraseña de forma segura',
            onTap: () => mostrarModalCambiarPassword(context, email: email, esOscuro: esOscuro),
          ),
          const SizedBox(height: 10),
          _FilaSeguridad(
            esOscuro: esOscuro,
            icono: Icons.verified_user_outlined,
            titulo: 'Actividad de la cuenta',
            subtitulo: 'Revisa tus dispositivos y actividad reciente',
            onTap: () => _mostrarActividadCuenta(context),
          ),
        ],
      ),
    );
  }
}

class _FilaSeguridad extends StatelessWidget {
  final bool esOscuro;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  const _FilaSeguridad({
    required this.esOscuro,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF262019) : const Color(0xFFFAF7F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CraftHubColors.borde(esOscuro)),
        ),
        child: Row(
          children: [
            Icon(icono, size: 19, color: CraftHubColors.vinoTinto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: CraftHubColors.textoPrincipal(esOscuro))),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(esOscuro))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: CraftHubColors.textoSecundario(esOscuro)),
          ],
        ),
      ),
    );
  }
}
