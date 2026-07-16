// lib/widgets/eventos/tarjeta_contacto_organizador.dart
//
// Muestra los datos de contacto directo de la entidad/organización que
// organiza el evento (teléfono, WhatsApp, correo, sitio web) para que el
// vendedor pueda coordinar su participación.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/evento_modelo.dart';

class TarjetaContactoOrganizador extends StatelessWidget {
  final OrganizadorEvento organizador;

  const TarjetaContactoOrganizador({super.key, required this.organizador});

  Future<void> _abrir(BuildContext context, Uri uri) async {
    final mensaje = tr(context, 'compartido.no_se_pudo_abrir_app');
    final exito = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!exito && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CraftHubColors.vinoTinto.withValues(alpha: oscuro ? 0.14 : 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.vinoTinto.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: CraftHubColors.vinoTinto,
                backgroundImage:
                    organizador.fotoUrl.isNotEmpty ? NetworkImage(organizador.fotoUrl) : null,
                child: organizador.fotoUrl.isEmpty
                    ? Text(
                        organizador.nombre.isNotEmpty
                            ? organizador.nombre[0].toUpperCase()
                            : 'O',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizador.nombre,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: CraftHubColors.textoPrincipal(oscuro),
                      ),
                    ),
                    Text(
                      organizador.tipo,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: CraftHubColors.textoSecundario(oscuro),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (organizador.telefono.isNotEmpty)
                _BotonContacto(
                  icono: Icons.call_outlined,
                  texto: organizador.telefono,
                  onTap: () => _abrir(
                      context, Uri(scheme: 'tel', path: organizador.telefono.replaceAll(' ', ''))),
                ),
              if (organizador.whatsapp.isNotEmpty)
                _BotonContacto(
                  icono: Icons.chat_bubble_outline_rounded,
                  texto: tr(context, 'compartido.whatsapp_label'),
                  onTap: () => _abrir(
                    context,
                    Uri.parse(
                      'https://wa.me/${organizador.whatsapp}?text=${Uri.encodeComponent(tr(context, 'compartido.whatsapp_mensaje_default'))}',
                    ),
                  ),
                ),
              if (organizador.email.isNotEmpty)
                _BotonContacto(
                  icono: Icons.mail_outline_rounded,
                  texto: tr(context, 'compartido.correo_label'),
                  onTap: () => _abrir(context, Uri(scheme: 'mailto', path: organizador.email)),
                ),
              if (organizador.sitioWeb.isNotEmpty)
                _BotonContacto(
                  icono: Icons.language_rounded,
                  texto: tr(context, 'compartido.sitio_web_label'),
                  onTap: () => _abrir(context, Uri.parse(organizador.sitioWeb)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonContacto extends StatefulWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _BotonContacto({required this.icono, required this.texto, required this.onTap});

  @override
  State<_BotonContacto> createState() => _BotonContactoState();
}

class _BotonContactoState extends State<_BotonContacto> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTinto : CraftHubColors.panel(oscuro),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CraftHubColors.vinoTinto, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icono,
                  size: 15, color: _hover ? Colors.white : CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              Text(
                widget.texto,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _hover ? Colors.white : CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
