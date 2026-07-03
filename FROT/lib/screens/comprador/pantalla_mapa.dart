import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../../widgets/comprador/tarjeta_artesano_mapa.dart';
import '../../widgets/comprador/popup_artesano_mapa.dart';
import '../../widgets/comprador/chip_categoria_mapa.dart';

// 🔌 Ruteo dentro de la app usando OSRM (Open Source Routing Machine), el
// mismo ecosistema de OpenStreetMap que ya usamos para los tiles del mapa.
// El servidor demo público es gratuito y no requiere API key, pero tiene
// límites de uso: para producción real se recomienda auto-hospedar OSRM
// o migrar a un servicio con SLA (Mapbox, GraphHopper, Google Directions).
class _ServicioRuta {
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Devuelve los puntos de la ruta y su distancia/duración estimada.
  static Future<({List<LatLng> puntos, double distanciaKm, int duracionMin})> obtenerRuta(
    LatLng origen,
    LatLng destino,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/route/v1/driving/'
      '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo calcular la ruta (${respuesta.statusCode})');
    }
    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
      throw Exception('No se encontró una ruta hacia ese destino');
    }
    final ruta = (data['routes'] as List).first as Map<String, dynamic>;
    final coordenadas = (ruta['geometry']['coordinates'] as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    return (
      puntos: coordenadas,
      distanciaKm: (ruta['distance'] as num) / 1000,
      duracionMin: ((ruta['duration'] as num) / 60).round(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELOS MOCK
// 🔗 API: GET /artesanos?categoria=&radio_km=
// ─────────────────────────────────────────────────────────────
class _ModeloArtesanoMapa {
  final String id;
  final String nombre;
  final String especialidad;
  final String ubicacion;
  final String fotoUrl;
  final LatLng posicion;
  final double distanciaKm;
  final bool enLinea;
  final String categoria;

  const _ModeloArtesanoMapa({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.ubicacion,
    required this.fotoUrl,
    required this.posicion,
    required this.distanciaKm,
    required this.enLinea,
    required this.categoria,
  });
}

class _ModeloCategoria {
  final String nombre;
  final String imagenUrl;
  final int total;

  const _ModeloCategoria({
    required this.nombre,
    required this.imagenUrl,
    required this.total,
  });
}

// Datos mock — reemplazar con llamada a FastAPI
final List<_ModeloArtesanoMapa> _artesanosMock = [
  _ModeloArtesanoMapa(
    id: '1', nombre: 'Rosa Martínez',
    especialidad: 'Tejedora tradicional',
    ubicacion: 'David, Chiriquí',
    fotoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    posicion: const LatLng(8.4343, -82.4322),
    distanciaKm: 2.3, enLinea: true, categoria: 'Textiles',
  ),
  _ModeloArtesanoMapa(
    id: '2', nombre: 'Carlos Ruiz',
    especialidad: 'Sombreros Pintao',
    ubicacion: 'David, Chiriquí',
    fotoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    posicion: const LatLng(8.0000, -80.5000),
    distanciaKm: 3.1, enLinea: false, categoria: 'Accesorios',
  ),
  _ModeloArtesanoMapa(
    id: '3', nombre: 'Ana Santos',
    especialidad: 'Molas y textiles',
    ubicacion: 'David, Chiriquí',
    fotoUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
    posicion: const LatLng(8.9943, -79.5188),
    distanciaKm: 4.8, enLinea: true, categoria: 'Textiles',
  ),
  _ModeloArtesanoMapa(
    id: '4', nombre: 'Miguel Torres',
    especialidad: 'Cerámica artesanal',
    ubicacion: 'David, Chiriquí',
    fotoUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
    posicion: const LatLng(7.8833, -80.4167),
    distanciaKm: 6.2, enLinea: false, categoria: 'Cerámica',
  ),
  _ModeloArtesanoMapa(
    id: '5', nombre: 'Elena García',
    especialidad: 'Joyería Emberá',
    ubicacion: 'David, Chiriquí',
    fotoUrl: 'https://randomuser.me/api/portraits/women/22.jpg',
    posicion: const LatLng(8.6667, -81.0833),
    distanciaKm: 8.7, enLinea: true, categoria: 'Joyería',
  ),
  _ModeloArtesanoMapa(
    id: '6', nombre: 'Luis Moreno',
    especialidad: 'Talla en madera',
    ubicacion: 'Bocas del Toro',
    fotoUrl: 'https://randomuser.me/api/portraits/men/71.jpg',
    posicion: const LatLng(9.3397, -82.2481),
    distanciaKm: 12.4, enLinea: false, categoria: 'Madera',
  ),
  _ModeloArtesanoMapa(
    id: '7', nombre: 'Carmen Pérez',
    especialidad: 'Decoración folclórica',
    ubicacion: 'Los Santos',
    fotoUrl: 'https://randomuser.me/api/portraits/women/55.jpg',
    posicion: const LatLng(7.9333, -80.4167),
    distanciaKm: 15.6, enLinea: true, categoria: 'Decoración',
  ),
];

final List<_ModeloCategoria> _categoriasMock = [
  _ModeloCategoria(nombre: 'Textiles',    imagenUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=200', total: 24),
  _ModeloCategoria(nombre: 'Cerámica',   imagenUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=200', total: 18),
  _ModeloCategoria(nombre: 'Madera',     imagenUrl: 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=200', total: 16),
  _ModeloCategoria(nombre: 'Joyería',    imagenUrl: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=200', total: 20),
  _ModeloCategoria(nombre: 'Decoración', imagenUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=200', total: 15),
  _ModeloCategoria(nombre: 'Accesorios', imagenUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=200', total: 12),
];

// ─────────────────────────────────────────────────────────────
// PANTALLA MAPA
// ─────────────────────────────────────────────────────────────
class PantallaMapa extends StatefulWidget {
  final bool esOscuro;
  const PantallaMapa({super.key, required this.esOscuro});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  final MapController _mapController = MapController();
  String? _categoriaSeleccionada;
  String? _idArtesanoSeleccionado;
  _ModeloArtesanoMapa? _artesanoPopup;
  double _radioKm = 25;
  final TextEditingController _ctrlBusqueda = TextEditingController();
  String _textoBusqueda = '';

  LatLng? _miUbicacion;
  List<LatLng> _rutaPuntos = [];
  bool _calculandoRuta = false;

  List<_ModeloArtesanoMapa> get _artesanosFiltrados {
    var lista = _artesanosMock;
    if (_categoriaSeleccionada != null) {
      lista = lista
          .where((a) => a.categoria == _categoriaSeleccionada)
          .toList();
    }
    if (_textoBusqueda.isNotEmpty) {
      lista = lista
          .where((a) =>
              a.nombre.toLowerCase().contains(_textoBusqueda.toLowerCase()) ||
              a.especialidad
                  .toLowerCase()
                  .contains(_textoBusqueda.toLowerCase()))
          .toList();
    }
    return lista;
  }

  void _seleccionarArtesano(_ModeloArtesanoMapa a) {
    setState(() {
      _idArtesanoSeleccionado = a.id;
      _artesanoPopup = a;
    });
    _mapController.move(a.posicion, 9.0);
  }

  void _cerrarPopup() {
    setState(() {
      _artesanoPopup = null;
      _idArtesanoSeleccionado = null;
    });
  }

  Future<LatLng> _obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activa el GPS/ubicación de tu dispositivo para calcular la ruta.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Necesitamos permiso de ubicación para trazar la ruta.');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception('El permiso de ubicación está bloqueado. Actívalo en los ajustes del dispositivo.');
    }
    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(posicion.latitude, posicion.longitude);
  }

  // Traza la ruta hacia [artesano] dentro del propio mapa (sin salir a apps
  // externas), usando la ubicación real del usuario como origen.
  Future<void> _calcularRutaHacia(_ModeloArtesanoMapa artesano) async {
    setState(() => _calculandoRuta = true);
    try {
      final origen = _miUbicacion ?? await _obtenerUbicacionActual();
      final resultado = await _ServicioRuta.obtenerRuta(origen, artesano.posicion);
      if (!mounted) return;
      setState(() {
        _miUbicacion = origen;
        _rutaPuntos = resultado.puntos;
        _calculandoRuta = false;
      });
      final bounds = LatLngBounds.fromPoints([origen, artesano.posicion, ...resultado.puntos]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(64)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta a ${artesano.nombre}: ${resultado.distanciaKm.toStringAsFixed(1)} km · ${resultado.duracionMin} min en auto',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _calculandoRuta = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _cerrarRuta() => setState(() => _rutaPuntos = []);

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    final colorFondo =
        esOscuro ? CraftHubColors.fondoOscuro : CraftHubColors.fondoClaro;
    final colorPanel =
        esOscuro ? CraftHubColors.panelOscuro : CraftHubColors.panelClaro;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ───────────────────────────────────────────────────
          _HeaderMapa(
            esOscuro: esOscuro,
            radioKm: _radioKm,
            alCambiarRadio: (v) => setState(() => _radioKm = v),
          ),

          // ── CUERPO: lista + mapa ──────────────────────────────────────
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel izquierdo
                  Container(
                    width: 248,
                    decoration: BoxDecoration(
                      color: colorPanel,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Buscador
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _CampoBusqueda(
                            controlador: _ctrlBusqueda,
                            esOscuro: esOscuro,
                            alCambiar: (v) =>
                                setState(() => _textoBusqueda = v),
                          ),
                        ),

                        // Lista artesanos
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            itemCount: _artesanosFiltrados.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 2),
                            itemBuilder: (_, i) {
                              final a = _artesanosFiltrados[i];
                              return TarjetaArtesanoMapa(
                                nombre: a.nombre,
                                especialidad: a.especialidad,
                                ubicacion: a.ubicacion,
                                fotoUrl: a.fotoUrl,
                                distanciaKm: a.distanciaKm,
                                enLinea: a.enLinea,
                                seleccionado:
                                    _idArtesanoSeleccionado == a.id,
                                alPresionar: () => _seleccionarArtesano(a),
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: i * 40),
                                    duration: 300.ms,
                                  );
                            },
                          ),
                        ),

                        // Ver todos
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _BotonVerTodos(
                            total: _artesanosMock.length,
                            esOscuro: esOscuro,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Mapa
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          // Flutter Map con OpenStreetMap
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter:
                                  const LatLng(8.5940, -80.1099),
                              initialZoom: 7.0,
                              onTap: (_, _) => _cerrarPopup(),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.crafthub.app',
                              ),
                              // Ruta trazada dentro del propio mapa (OSRM)
                              if (_rutaPuntos.isNotEmpty)
                                PolylineLayer(polylines: [
                                  Polyline(
                                    points: _rutaPuntos,
                                    strokeWidth: 5,
                                    color: CraftHubColors.vinoTinto,
                                    borderStrokeWidth: 2,
                                    borderColor: Colors.white,
                                  ),
                                ]),
                              // Marcadores
                              MarkerLayer(
                                markers: [
                                  ..._artesanosFiltrados.map((a) {
                                    final seleccionado =
                                        _idArtesanoSeleccionado == a.id;
                                    return Marker(
                                      point: a.posicion,
                                      width: seleccionado ? 80 : 68,
                                      height: seleccionado ? 90 : 76,
                                      child: GestureDetector(
                                        onTap: () => _seleccionarArtesano(a),
                                        child: _PinArtesano(
                                          fotoUrl: a.fotoUrl,
                                          distanciaKm: a.distanciaKm,
                                          seleccionado: seleccionado,
                                        ),
                                      ),
                                    );
                                  }),
                                  if (_miUbicacion != null)
                                    Marker(
                                      point: _miUbicacion!,
                                      width: 22,
                                      height: 22,
                                      child: const _PinMiUbicacion(),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          // Popup artesano seleccionado
                          if (_artesanoPopup != null)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: PopupArtesanoMapa(
                                nombre: _artesanoPopup!.nombre,
                                especialidad: _artesanoPopup!.especialidad,
                                fotoUrl: _artesanoPopup!.fotoUrl,
                                latitud: _artesanoPopup!.posicion.latitude,
                                longitud: _artesanoPopup!.posicion.longitude,
                                distanciaKm: _artesanoPopup!.distanciaKm,
                                calculandoRuta: _calculandoRuta,
                                alCerrar: _cerrarPopup,
                                alComoLlegar: () =>
                                    _calcularRutaHacia(_artesanoPopup!),
                                alVerPerfil: () {
                                  // TODO: navegar a PantallaPerfilArtesano
                                },
                              ).animate().fadeIn(duration: 200.ms).slideY(
                                    begin: -0.1,
                                    end: 0,
                                    duration: 200.ms,
                                  ),
                            ),

                          // Chip para quitar la ruta trazada
                          if (_rutaPuntos.isNotEmpty)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: _ChipCerrarRuta(onTap: _cerrarRuta),
                            ),

                          // Controles zoom
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: _ControlesZoom(
                                mapController: _mapController),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CATEGORÍAS ────────────────────────────────────────────────
          _SeccionCategorias(
            categorias: _categoriasMock,
            categoriaSeleccionada: _categoriaSeleccionada,
            esOscuro: esOscuro,
            alSeleccionar: (cat) {
              setState(() {
                _categoriaSeleccionada =
                    _categoriaSeleccionada == cat ? null : cat;
              });
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _HeaderMapa extends StatelessWidget {
  final bool esOscuro;
  final double radioKm;
  final ValueChanged<double> alCambiarRadio;

  const _HeaderMapa({
    required this.esOscuro,
    required this.radioKm,
    required this.alCambiarRadio,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Volver
          _BotonVolverMapa(esOscuro: esOscuro),
          const SizedBox(width: 14),

          // Ícono + título
          Icon(Icons.map_outlined,
              size: 28, color: CraftHubColors.vinoTinto),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artesanos cerca de ti',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTexto,
                ),
              ),
              Text(
                'Descubre talento local en tu área',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Selector de radio
          _SelectorRadio(
            radioKm: radioKm,
            esOscuro: esOscuro,
            alCambiar: alCambiarRadio,
          ),

          const SizedBox(width: 10),

          // Usar mi ubicación
          _BotonUbicacion(esOscuro: esOscuro),
        ],
      ),
    );
  }
}

class _BotonVolverMapa extends StatefulWidget {
  final bool esOscuro;
  const _BotonVolverMapa({required this.esOscuro});

  @override
  State<_BotonVolverMapa> createState() => _BotonVolverMapaState();
}

class _BotonVolverMapaState extends State<_BotonVolverMapa> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.panel(widget.esOscuro)
                : CraftHubColors.fondo(widget.esOscuro),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.borde(widget.esOscuro)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded,
                  size: 16, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoPrincipal(widget.esOscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorRadio extends StatelessWidget {
  final double radioKm;
  final bool esOscuro;
  final ValueChanged<double> alCambiar;

  const _SelectorRadio({
    required this.radioKm,
    required this.esOscuro,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final opciones = [10.0, 25.0, 50.0, 100.0];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esOscuro ? CraftHubColors.panelOscuro : CraftHubColors.panelClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CraftHubColors.bordeClaro, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: radioKm,
          isDense: true,
          dropdownColor: esOscuro
              ? CraftHubColors.panelOscuro
              : CraftHubColors.panelClaro,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
          items: opciones
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text('Dentro de ${o.toInt()} km'),
                  ))
              .toList(),
          onChanged: (v) => alCambiar(v ?? 25),
        ),
      ),
    );
  }
}

class _BotonUbicacion extends StatefulWidget {
  final bool esOscuro;
  const _BotonUbicacion({required this.esOscuro});

  @override
  State<_BotonUbicacion> createState() => _BotonUbicacionState();
}

class _BotonUbicacionState extends State<_BotonUbicacion> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // TODO: obtener ubicación real con geolocator
          // 🔗 API: GET /artesanos/cercanos?lat=&lng=&radio_km=
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoOscuro
                : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: CraftHubColors.vinoTinto.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 15),
              SizedBox(width: 8),
              Text(
                'Usar mi ubicación',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────
// PIN EN EL MAPA
// ─────────────────────────────────────────────────────────────
class _PinArtesano extends StatelessWidget {
  final String fotoUrl;
  final double distanciaKm;
  final bool seleccionado;

  const _PinArtesano({
    required this.fotoUrl,
    required this.distanciaKm,
    required this.seleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Distancia
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: seleccionado
                ? CraftHubColors.vinoTinto
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            '${distanciaKm.toStringAsFixed(1)} km',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: seleccionado ? Colors.white : CraftHubColors.textoClaro,
            ),
          ),
        ),
        const SizedBox(height: 3),
        // Avatar circular con borde
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: seleccionado ? 52 : 44,
          height: seleccionado ? 52 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: seleccionado
                  ? CraftHubColors.vinoTinto
                  : Colors.white,
              width: seleccionado ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
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
                        color: CraftHubColors.textoSecClaro),
                  ),
          ),
        ),
        // Punta del pin
        CustomPaint(
          size: const Size(12, 7),
          painter: _PintaPunta(
            color: seleccionado ? CraftHubColors.vinoTinto : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PintaPunta extends CustomPainter {
  final Color color;
  const _PintaPunta({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// PUNTO DE "MI UBICACIÓN" (origen de la ruta)
// ─────────────────────────────────────────────────────────────
class _PinMiUbicacion extends StatelessWidget {
  const _PinMiUbicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CraftHubColors.info,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIP PARA QUITAR LA RUTA TRAZADA
// ─────────────────────────────────────────────────────────────
class _ChipCerrarRuta extends StatelessWidget {
  final VoidCallback onTap;
  const _ChipCerrarRuta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 15, color: CraftHubColors.vinoTinto),
            SizedBox(width: 6),
            Text(
              'Quitar ruta',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CraftHubColors.textoClaro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTROLES DE ZOOM
// ─────────────────────────────────────────────────────────────
class _ControlesZoom extends StatelessWidget {
  final MapController mapController;
  const _ControlesZoom({required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _BtnZoom(
            icono: Icons.add_rounded,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom + 1,
            ),
          ),
          Container(height: 1, color: CraftHubColors.bordeClaro),
          _BtnZoom(
            icono: Icons.remove_rounded,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom - 1,
            ),
          ),
          Container(height: 1, color: CraftHubColors.bordeClaro),
          _BtnZoom(
            icono: Icons.my_location_rounded,
            onTap: () => mapController.move(
              const LatLng(8.5940, -80.1099),
              7.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BtnZoom extends StatefulWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BtnZoom({required this.icono, required this.onTap});

  @override
  State<_BtnZoom> createState() => _BtnZoomState();
}

class _BtnZoomState extends State<_BtnZoom> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          color: _sobre
              ? CraftHubColors.vinoTintoSuave
              : Colors.transparent,
          child: Icon(widget.icono,
              size: 18, color: CraftHubColors.textoClaro),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CAMPO DE BÚSQUEDA
// ─────────────────────────────────────────────────────────────
class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controlador;
  final bool esOscuro;
  final ValueChanged<String> alCambiar;

  const _CampoBusqueda({
    required this.controlador,
    required this.esOscuro,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      onChanged: alCambiar,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: CraftHubColors.textoPrincipal(esOscuro),
      ),
      decoration: InputDecoration(
        hintText: 'Buscar artesanos...',
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: CraftHubColors.textoSecundario(esOscuro),
        ),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: CraftHubColors.textoSecClaro),
        filled: true,
        fillColor: esOscuro
            ? CraftHubColors.panelOscuro2
            : CraftHubColors.fondoClaro,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: CraftHubColors.bordeClaro, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: CraftHubColors.vinoTinto, width: 1.3),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN VER TODOS
// ─────────────────────────────────────────────────────────────
class _BotonVerTodos extends StatefulWidget {
  final int total;
  final bool esOscuro;
  const _BotonVerTodos({required this.total, required this.esOscuro});

  @override
  State<_BotonVerTodos> createState() => _BotonVerTodosState();
}

class _BotonVerTodosState extends State<_BotonVerTodos> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoSuave
                : (widget.esOscuro
                    ? CraftHubColors.panelOscuro2
                    : CraftHubColors.fondoClaro),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ver todos (${widget.total})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  size: 15, color: CraftHubColors.vinoTinto),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN CATEGORÍAS
// ─────────────────────────────────────────────────────────────
class _SeccionCategorias extends StatelessWidget {
  final List<_ModeloCategoria> categorias;
  final String? categoriaSeleccionada;
  final bool esOscuro;
  final ValueChanged<String> alSeleccionar;

  const _SeccionCategorias({
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.esOscuro,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Explorar artesanos por categoría',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CraftHubColors.textoPrincipal(esOscuro),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Chips de categorías
              ...categorias.map((c) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChipCategoriaMapa(
                  nombre: c.nombre,
                  imagenUrl: c.imagenUrl,
                  totalArtesanos: c.total,
                  seleccionado: categoriaSeleccionada == c.nombre,
                  alPresionar: () => alSeleccionar(c.nombre),
                ).animate().fadeIn(duration: 300.ms),
              )),

              // Más categorías
              _BotonMasCategorias(esOscuro: esOscuro),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonMasCategorias extends StatefulWidget {
  final bool esOscuro;
  const _BotonMasCategorias({required this.esOscuro});

  @override
  State<_BotonMasCategorias> createState() => _BotonMasCategoriasState();
}

class _BotonMasCategoriasState extends State<_BotonMasCategorias> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoSuave
                : (widget.esOscuro
                    ? CraftHubColors.panelOscuro
                    : CraftHubColors.panelClaro),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1.2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Más categorías',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              SizedBox(height: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: CraftHubColors.vinoTinto),
            ],
          ),
        ),
      ),
    );
  }
}