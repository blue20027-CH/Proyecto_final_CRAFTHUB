import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class PopupArtesanoMapa extends StatelessWidget {
  final String nombre;
  final String especialidad;
  final String fotoUrl;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final VoidCallback alCerrar;
  final VoidCallback alVerPerfil;

  const PopupArtesanoMapa({
    super.key,
    required this.nombre,
    required this.especialidad,
    required this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.distanciaKm,
    required this.alCerrar,
    required this.alVerPerfil,
  });

  // Tiempos estimados de viaje por tipo
  String _tiempoEstimado(String medio) {
    final minutos = switch (medio) {
      'auto'    => (distanciaKm / 50 * 60).round(),
      'moto'    => (distanciaKm / 40 * 60).round(),
      'caminando' => (distanciaKm / 5 * 60).round(),
      _ => 0,
    };
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Future<void> _abrirGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitud,$longitud&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: CraftHubColors.panelClaro,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── HEADER con foto ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CraftHubColors.vinoTinto.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Foto perfil
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: CraftHubColors.vinoTinto, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: fotoUrl.isNotEmpty
                        ? Image.network(fotoUrl, fit: BoxFit.cover)
                        : Container(
                            color: CraftHubColors.bordeClaro,
                            child: const Icon(Icons.person,
                                color: CraftHubColors.textoSecClaro,
                                size: 30),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CraftHubColors.textoClaro,
                        ),
                      ),
                      Text(
                        especialidad,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: CraftHubColors.textoSecClaro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12,
                              color: CraftHubColors.vinoTinto),
                          const SizedBox(width: 3),
                          Text(
                            '${distanciaKm.toStringAsFixed(1)} km de distancia',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CraftHubColors.vinoTinto,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cerrar
                GestureDetector(
                  onTap: alCerrar,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: CraftHubColors.textoSecClaro),
                  ),
                ),
              ],
            ),
          ),

          // ── TIEMPOS DE VIAJE ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiempo estimado para llegar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CraftHubColors.textoSecClaro,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ChipTiempo(
                      icono: Icons.directions_car_outlined,
                      medio: 'Auto',
                      tiempo: _tiempoEstimado('auto'),
                    ),
                    _ChipTiempo(
                      icono: Icons.two_wheeler_outlined,
                      medio: 'Moto',
                      tiempo: _tiempoEstimado('moto'),
                    ),
                    _ChipTiempo(
                      icono: Icons.directions_walk_outlined,
                      medio: 'Caminando',
                      tiempo: _tiempoEstimado('caminando'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── BOTONES ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Botón direcciones (estilo Google Maps)
                _BotonDireccion(alPresionar: _abrirGoogleMaps),
                const SizedBox(height: 8),
                // Ver perfil
                _BotonVerPerfil(alPresionar: alVerPerfil),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTiempo extends StatelessWidget {
  final IconData icono;
  final String medio;
  final String tiempo;

  const _ChipTiempo({
    required this.icono,
    required this.medio,
    required this.tiempo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: CraftHubColors.fondoClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CraftHubColors.bordeClaro),
          ),
          child: Icon(icono, size: 20, color: CraftHubColors.vinoTinto),
        ),
        const SizedBox(height: 4),
        Text(
          tiempo,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CraftHubColors.textoClaro,
          ),
        ),
        Text(
          medio,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: CraftHubColors.textoSecClaro,
          ),
        ),
      ],
    );
  }
}

class _BotonDireccion extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonDireccion({required this.alPresionar});

  @override
  State<_BotonDireccion> createState() => _BotonDireccionState();
}

class _BotonDireccionState extends State<_BotonDireccion> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoOscuro
                : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: CraftHubColors.vinoTinto.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Cómo llegar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonVerPerfil extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonVerPerfil({required this.alPresionar});

  @override
  State<_BotonVerPerfil> createState() => _BotonVerPerfilState();
}

class _BotonVerPerfilState extends State<_BotonVerPerfil> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoSuave
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: CraftHubColors.bordeClaro, width: 1.2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined,
                  color: CraftHubColors.textoClaro, size: 15),
              SizedBox(width: 8),
              Text(
                'Ver perfil del artesano',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}