import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TarjetaArtesanoMapa extends StatefulWidget {
  final String nombre;
  final String especialidad;
  final String ubicacion;
  final String fotoUrl;
  final double distanciaKm;
  final bool seleccionado;
  final bool enLinea;
  final VoidCallback alPresionar;

  const TarjetaArtesanoMapa({
    super.key,
    required this.nombre,
    required this.especialidad,
    required this.ubicacion,
    required this.fotoUrl,
    required this.distanciaKm,
    required this.seleccionado,
    required this.alPresionar,
    this.enLinea = false,
  });

  @override
  State<TarjetaArtesanoMapa> createState() => _TarjetaArtesanoMapaState();
}

class _TarjetaArtesanoMapaState extends State<TarjetaArtesanoMapa> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    final fondo = widget.seleccionado
        ? CraftHubColors.vinoTintoSuave
        : (_sobreEl ? const Color(0xFFF5F0EA) : Colors.transparent);
    final borde = widget.seleccionado
        ? CraftHubColors.vinoTinto.withOpacity(0.4)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borde, width: 1.2),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: CraftHubColors.bordeClaro,
                    backgroundImage: widget.fotoUrl.isNotEmpty
                        ? NetworkImage(widget.fotoUrl)
                        : null,
                    child: widget.fotoUrl.isEmpty
                        ? const Icon(Icons.person,
                            color: CraftHubColors.textoSecClaro)
                        : null,
                  ),
                  if (widget.enLinea)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nombre,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CraftHubColors.textoClaro,
                      ),
                    ),
                    Text(
                      widget.especialidad,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: CraftHubColors.textoSecClaro,
                      ),
                    ),
                    Text(
                      widget.ubicacion,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: CraftHubColors.textoSecClaro,
                      ),
                    ),
                  ],
                ),
              ),

              // Distancia
              Text(
                '${widget.distanciaKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}