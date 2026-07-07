import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/artesano_modelo.dart';
import '../../services/api_service.dart';
import '../../widgets/comprador/tarjeta_artesano.dart';
import '../../widgets/comprador/panel_perfil_artesano.dart';
import 'pantalla_perfil_artesano.dart';


// CategorÃ­as y provincias para filtros
// ðŸ”Œ GET /api/categorias y GET /api/provincias
const List<String> _categorias = [
  'Todas las categorÃ­as', 'Textiles', 'CerÃ¡mica', 'Madera',
  'JoyerÃ­a', 'Sombreros', 'CesterÃ­a', 'ArtesanÃ­as',
];
const List<String> _provincias = [
  'Todas las provincias', 'Bocas del Toro', 'ChiriquÃ­', 'CoclÃ©',
  'ColÃ³n', 'DariÃ©n', 'Herrera', 'Los Santos', 'PanamÃ¡',
  'PanamÃ¡ Oeste', 'Veraguas', 'Guna Yala', 'NgÃ¤be-BuglÃ©',
  'EmberÃ¡-Wounaan',
];
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ArtesanosScreen extends StatefulWidget {
  const ArtesanosScreen({super.key});

  @override
  State<ArtesanosScreen> createState() => _ArtesanosScreenState();
}

class _ArtesanosScreenState extends State<ArtesanosScreen> {
  String _categoriaSeleccionada = _categorias.first;
  String _provinciaSeleccionada = _provincias.first;
  int _artesanoSeleccionado = 0;
  bool _cargando = true;
  String? _error;
  List<ArtesanoModelo> _artesanos = [];

  List<ArtesanoModelo> get _artesanosFiltrados => _artesanos;

  @override
  void initState() {
    super.initState();
    _cargarArtesanos();
  }

  Future<void> _cargarArtesanos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final artesanos = await ApiService.getArtesanos(
        categoria: _categoriaSeleccionada,
        provincia: _provinciaSeleccionada,
        limite: 8,
      );
      if (!mounted) return;
      setState(() {
        _artesanos = artesanos;
        _artesanoSeleccionado = 0;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(oscuro),
      body: Row(children: [

        // â”€â”€ CONTENIDO PRINCIPAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: Column(children: [

            // â”€â”€ CUERPO (TopBar eliminado desde aquÃ­) â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Row(children: [

                // â”€â”€ PANEL IZQUIERDO: lista â”€â”€
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Encabezado
                      _EncabezadoSeccion(oscuro: oscuro),
                      const SizedBox(height: 18),

                      // Filtros
                      _FilasFiltos(
                        categoriaSeleccionada: _categoriaSeleccionada,
                        provinciaSeleccionada: _provinciaSeleccionada,
                        onCategoria: (v) {
                          setState(() => _categoriaSeleccionada = v);
                          _cargarArtesanos();
                        },
                        onProvincia: (v) {
                          setState(() => _provinciaSeleccionada = v);
                          _cargarArtesanos();
                        },
                      ),
                      const SizedBox(height: 18),

                      if (_cargando)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _EstadoVacio(
                          oscuro: oscuro,
                          icono: Icons.wifi_off_rounded,
                          titulo: 'No se pudieron cargar los artesanos',
                          mensaje: _error ?? 'Error desconocido',
                          textoBoton: 'Reintentar',
                          onPressed: _cargarArtesanos,
                        )
                      else if (_artesanosFiltrados.isEmpty)
                        _EstadoVacio(
                          oscuro: oscuro,
                          icono: Icons.storefront_outlined,
                          titulo: 'No hay artesanos con productos',
                          mensaje: 'Cuando un vendedor tenga productos publicados aparecera aqui.',
                          textoBoton: 'Actualizar',
                          onPressed: _cargarArtesanos,
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _artesanosFiltrados.length,
                          itemBuilder: (_, i) => TarjetaArtesano(
                            artesano: _artesanosFiltrados[i],
                            estaSeleccionado: _artesanoSeleccionado == i,
                            alPresionar: () => setState(() => _artesanoSeleccionado = i),
                            alCambiarFavorito: (_) {},
                          ),
                        ),
                    ]),
                  ),
                ),

                // â”€â”€ PANEL DERECHO: perfil â”€â”€
                if (!_cargando && _error == null && _artesanosFiltrados.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: PanelPerfilArtesano(
                      key: ValueKey(_artesanosFiltrados[_artesanoSeleccionado].id),
                      artesano: _artesanosFiltrados[_artesanoSeleccionado],
                      alVerProductos: () async {
  final artesanoActual = _artesanosFiltrados[_artesanoSeleccionado];
  try {
    final detalle = await ApiService.getDetalleArtesano(artesanoActual.nombre);
    final productosRaw = detalle['productos'] as List<dynamic>? ?? [];
    final productos = productosRaw
        .map((p) => ModeloProductoResumen.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();

    final categorias = productos.map((p) => p.coleccion).toSet().toList();

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPerfilArtesano(
          artesano: ModeloArtesano(
            nombre: artesanoActual.nombre,
            specialty: artesanoActual.especialidad,
            especialidad: artesanoActual.especialidad,
            ubicacion: artesanoActual.provincia,
            fotoUrl: artesanoActual.fotoUrl,
            bannerUrl: artesanoActual.bannerEfectivo,
            calificacion: artesanoActual.rating,
            totalResenas: artesanoActual.totalResenas,
            verificado: artesanoActual.estaVerificado,
            totalProductos: productos.length,
            anosEnCraftHub: artesanoActual.anosExperiencia,
            valoracionesPositivas: artesanoActual.totalResenas,
            ventasRealizadas: artesanoActual.totalVentas,
            descripcion: artesanoActual.descripcion,
            etiquetas: artesanoActual.especialidades,
            colecciones: categorias,
            productos: productos,
          ),
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error cargando detalle artesano: $e');
  }
},
                      alEnviarMensaje: () {
                        // ðŸ”Œ Navigator.pushNamed(context, '/chat',
                        //       arguments: artesano.id)
                      },
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// â”€â”€ Widgets auxiliares de la pantalla â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EstadoVacio extends StatelessWidget {
  final bool oscuro;
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String textoBoton;
  final VoidCallback onPressed;

  const _EstadoVacio({
    required this.oscuro,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.textoBoton,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 42, color: CraftHubColors.vinoTinto),
          const SizedBox(height: 12),
          Text(titulo,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(oscuro),
              )),
          const SizedBox(height: 6),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: CraftHubColors.textoSecundario(oscuro),
              )),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(textoBoton, style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  final bool oscuro;
  const _EncabezadoSeccion({required this.oscuro});

  @override
  Widget build(BuildContext context) {
    // ðŸ”Œ totalArtesanos viene de GET /api/artesanos/stats
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Artesanos',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(width: 8),
          const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFC9A84C)),
        ]),
        const SizedBox(height: 4),
        Text('Conoce a los talentosos artesanos que mantienen vivas\nnuestras tradiciones y cultura panameÃ±a.',
          style: GoogleFonts.poppins(fontSize: 12, height: 1.55,
              color: CraftHubColors.textoSecundario(oscuro))),
      ])),

      // Stat: artesanos activos
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(oscuro),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CraftHubColors.borde(oscuro), width: 0.8),
        ),
        child: Row(children: [
          Icon(Icons.people_outline_rounded, size: 22,
              color: CraftHubColors.vinoTinto),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('+250', // ðŸ”Œ reemplazar con total del backend
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(oscuro))),
            Text('Artesanos activos',
              style: GoogleFonts.poppins(fontSize: 10,
                  color: CraftHubColors.textoSecundario(oscuro))),
          ]),
        ]),
      ),
    ]);
  }
}

class _FilasFiltos extends StatelessWidget {
  final String categoriaSeleccionada;
  final String provinciaSeleccionada;
  final Function(String) onCategoria;
  final Function(String) onProvincia;

  const _FilasFiltos({
    required this.categoriaSeleccionada,
    required this.provinciaSeleccionada,
    required this.onCategoria,
    required this.onProvincia,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      // Dropdown categorÃ­a â€” ðŸ”Œ GET /api/categorias
      _DropdownFiltro(
        valor: categoriaSeleccionada,
        opciones: _categorias,
        onSeleccionar: onCategoria,
        oscuro: oscuro,
      ),
      const SizedBox(width: 8),
      // Dropdown provincia â€” ðŸ”Œ GET /api/provincias
      _DropdownFiltro(
        valor: provinciaSeleccionada,
        opciones: _provincias,
        onSeleccionar: onProvincia,
        oscuro: oscuro,
      ),
      const SizedBox(width: 8),
      // BotÃ³n mÃ¡s filtros
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(oscuro),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: CraftHubColors.borde(oscuro), width: 0.8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, size: 14,
              color: CraftHubColors.textoSecundario(oscuro)),
          const SizedBox(width: 5),
          Text('MÃ¡s filtros',
            style: GoogleFonts.poppins(fontSize: 12,
                color: CraftHubColors.textoSecundario(oscuro))),
        ]),
      ),
    ]);
  }
}

class _DropdownFiltro extends StatelessWidget {
  final String valor;
  final List<String> opciones;
  final Function(String) onSeleccionar;
  final bool oscuro;

  const _DropdownFiltro({
    required this.valor, required this.opciones,
    required this.onSeleccionar, required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSeleccionar,
      itemBuilder: (_) => opciones.map((op) => PopupMenuItem(
        value: op,
        child: Text(op, style: GoogleFonts.poppins(fontSize: 13)),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(oscuro),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: CraftHubColors.borde(oscuro), width: 0.8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(valor,
            style: GoogleFonts.poppins(fontSize: 12,
                color: CraftHubColors.textoSecundario(oscuro))),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14,
              color: CraftHubColors.textoSecundario(oscuro)),
        ]),
      ),
    );
  }
}
