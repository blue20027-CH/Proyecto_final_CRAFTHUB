// lib/widgets/comprador/tarjeta_seccion.dart
// Contenedor de tarjeta-sección reutilizado por las secciones de "Mi
// perfil"/Configuración (historial de facturas, preferencias, métodos de
// pago, seguridad) para que todas compartan el mismo estilo visual: panel +
// borde + sombra suave, con encabezado icono/título/subtítulo y, opcional,
// un botón de acción o una flecha para colapsar el contenido.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TarjetaSeccion extends StatefulWidget {
  final bool esOscuro;
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final bool colapsable;
  final bool inicialmenteExpandido;
  final Widget child;
  const TarjetaSeccion({
    super.key,
    required this.esOscuro,
    required this.icono,
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.accion,
    this.colapsable = false,
    this.inicialmenteExpandido = true,
  });

  @override
  State<TarjetaSeccion> createState() => _TarjetaSeccionState();
}

class _TarjetaSeccionState extends State<TarjetaSeccion> {
  late bool _expandido = widget.inicialmenteExpandido;

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.colapsable ? () => setState(() => _expandido = !_expandido) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34, height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CraftHubColors.vinoTintoSuave,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icono, size: 17, color: CraftHubColors.vinoTinto),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.titulo,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700,
                              color: CraftHubColors.textoPrincipal(esOscuro))),
                      if (widget.subtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(widget.subtitulo!,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.textoSecundario(esOscuro))),
                      ],
                    ],
                  ),
                ),
                ?widget.accion,
                if (widget.colapsable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _expandido ? 0.5 : 0,
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: CraftHubColors.textoSecundario(esOscuro)),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !widget.colapsable || _expandido
                ? Padding(padding: const EdgeInsets.only(top: 14), child: widget.child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
