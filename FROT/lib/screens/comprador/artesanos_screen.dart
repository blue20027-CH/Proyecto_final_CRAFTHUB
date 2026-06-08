import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/artesano_modelo_prueba.dart';
import '../../widgets/comprador/tarjeta_artesano.dart';
import '../../widgets/comprador/panel_perfil_artesano.dart';
import 'pantalla_perfil_artesano.dart';

// ─────────────────────────────────────────────────────────────
// 🔌 DATOS MOCK — reemplazar con GET /api/artesanos/destacados
// y GET /api/artesanos?categoria=X&provincia=Y&pagina=1
// ─────────────────────────────────────────────────────────────
final List<ArtesanoModelo> mockArtesanos = [
  ArtesanoModelo(
    id: 'a1', nombre: 'Rosa Martínez', especialidad: 'Tejedora tradicional',
    categoria: 'Textiles', provincia: 'Chiriquí',
    fotoUrl: 'https://i.pravatar.cc/150?img=5',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=600',
    rating: 4.9, totalResenas: 128, totalVentas: 320, anosExperiencia: 15,
    estaVerificado: true,
    especialidades: ['Bolsos tejidos', 'Caminos de mesa', 'Tapices', 'Hamacas', 'Cojines decorativos'],
    descripcion: 'Más de 15 años dedicados al arte del tejido tradicional. Sus piezas están inspiradas en la naturaleza y las historias de nuestra cultura.',
  ),
  ArtesanoModelo(
    id: 'a2', nombre: 'Carlos Ruiz', especialidad: 'Sombreros y fibras',
    categoria: 'Sombreros', provincia: 'Los Santos',
    fotoUrl: 'https://i.pravatar.cc/150?img=3',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    rating: 4.8, totalResenas: 96, totalVentas: 210, anosExperiencia: 20,
    estaVerificado: true,
    especialidades: ['Sombreros pintaos', 'Sombreros de paja', 'Fibras naturales'],
    descripcion: 'Artesano con 20 años de experiencia en el arte del sombrero pintao, declarado patrimonio de la humanidad.',
  ),
  ArtesanoModelo(
    id: 'a3', nombre: 'Ana Santos', especialidad: 'Molas y textiles',
    categoria: 'Textiles', provincia: 'Guna Yala',
    fotoUrl: 'https://i.pravatar.cc/150?img=1',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
    rating: 4.8, totalResenas: 152, totalVentas: 430, anosExperiencia: 12,
    estaVerificado: true,
    especialidades: ['Molas originales', 'Textiles Guna', 'Bolsos mola'],
    descripcion: 'Maestra mola de la comarca Guna Yala. Cada pieza cuenta una historia de nuestra tradición ancestral.',
  ),
  ArtesanoModelo(
    id: 'a4', nombre: 'Miguel Torres', especialidad: 'Cerámica artesanal',
    categoria: 'Cerámica', provincia: 'Herrera',
    fotoUrl: 'https://i.pravatar.cc/150?img=8',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
    rating: 4.7, totalResenas: 84, totalVentas: 185, anosExperiencia: 10,
    estaVerificado: false,
    especialidades: ['Vasijas', 'Platos decorativos', 'Figuras de barro'],
    descripcion: 'Ceramista especializado en técnicas prehispánicas rescatadas de la provincia de Herrera.',
  ),
  ArtesanoModelo(
    id: 'a5', nombre: 'Elena García', especialidad: 'Joyería Emberá',
    categoria: 'Joyería', provincia: 'Darién',
    fotoUrl: 'https://i.pravatar.cc/150?img=9',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1603912699214-92627f304eb6?w=600',
    rating: 4.9, totalResenas: 110, totalVentas: 290, anosExperiencia: 8,
    estaVerificado: true,
    especialidades: ['Collares', 'Pulseras', 'Pendientes', 'Chaquiras'],
    descripcion: 'Artesana Emberá especializada en joyería tradicional hecha con semillas y chaquiras de colores.',
  ),
  ArtesanoModelo(
    id: 'a6', nombre: 'Pedro Díaz', especialidad: 'Tallado en madera',
    categoria: 'Madera', provincia: 'Veraguas',
    fotoUrl: 'https://i.pravatar.cc/150?img=12',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=600',
    rating: 4.8, totalResenas: 76, totalVentas: 140, anosExperiencia: 18,
    estaVerificado: true,
    especialidades: ['Figuras talladas', 'Máscaras', 'Utensilios de madera'],
    descripcion: 'Maestro tallador con 18 años de experiencia trabajando maderas nobles de los bosques panameños.',
  ),
  ArtesanoModelo(
    id: 'a7', nombre: 'Lucía Pérez', especialidad: 'Cestería artesanal',
    categoria: 'Cestería', provincia: 'Panamá Oeste',
    fotoUrl: 'https://i.pravatar.cc/150?img=15',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=600',
    rating: 4.7, totalResenas: 68, totalVentas: 175, anosExperiencia: 11,
    estaVerificado: false,
    especialidades: ['Canastas', 'Cestos de palma', 'Bandejas'],
    descripcion: 'Especialista en cestería con fibras naturales de palma y junco, técnicas heredadas de su abuela.',
  ),
  ArtesanoModelo(
    id: 'a8', nombre: 'José Morales', especialidad: 'Máscaras tradicionales',
    categoria: 'Artesanías', provincia: 'Colón',
    fotoUrl: 'https://i.pravatar.cc/150?img=11',
    fotoPortadaUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    rating: 4.9, totalResenas: 98, totalVentas: 220, anosExperiencia: 14,
    estaVerificado: true,
    especialidades: ['Máscaras de diablo', 'Carnaval', 'Figuras rituales'],
    descripcion: 'Creador de máscaras para el festival del diablo mayor de Colón. Cada máscara es una obra de arte única.',
  ),
];

// Categorías y provincias para filtros
// 🔌 GET /api/categorias y GET /api/provincias
const List<String> _categorias = [
  'Todas las categorías', 'Textiles', 'Cerámica', 'Madera',
  'Joyería', 'Sombreros', 'Cestería', 'Artesanías',
];
const List<String> _provincias = [
  'Todas las provincias', 'Bocas del Toro', 'Chiriquí', 'Coclé',
  'Colón', 'Darién', 'Herrera', 'Los Santos', 'Panamá',
  'Panamá Oeste', 'Veraguas', 'Guna Yala', 'Ngäbe-Buglé',
  'Emberá-Wounaan',
];
// ─────────────────────────────────────────────────────────────

class ArtesanosScreen extends StatefulWidget {
  const ArtesanosScreen({super.key});

  @override
  State<ArtesanosScreen> createState() => _ArtesanosScreenState();
}

class _ArtesanosScreenState extends State<ArtesanosScreen> {
  // ── Estado de filtros ──
  String _categoriaSeleccionada = 'Todas las categorías';
  String _provinciaSeleccionada = 'Todas las provincias';

  // ── Artesano seleccionado en el panel derecho ──
  int _artesanoSeleccionado = 0;

  // ── Lista filtrada ──
  // 🔌 Reemplazar con llamada: GET /api/artesanos?categoria=X&provincia=Y
  List<ArtesanoModelo> get _artesanosFiltrados {
    return mockArtesanos.where((a) {
      final cumpleCategoria = _categoriaSeleccionada == 'Todas las categorías'
          || a.categoria == _categoriaSeleccionada;
      final cumpleProvincia = _provinciaSeleccionada == 'Todas las provincias'
          || a.provincia == _provinciaSeleccionada;
      return cumpleCategoria && cumpleProvincia;
    }).toList();
  }

  ModeloArtesano _convertirAModeloArtesano(ArtesanoModelo artesano) {
    return ModeloArtesano(
      nombre: artesano.nombre,
      specialty: artesano.especialidad,
      especialidad: artesano.especialidad,
      ubicacion: artesano.provincia,
      fotoUrl: artesano.fotoUrl,
      bannerUrl: artesano.fotoPortadaUrl,
      calificacion: artesano.rating,
      totalResenas: artesano.totalResenas,
      verificado: artesano.estaVerificado,
      totalProductos: artesano.totalVentas,
      anosEnCraftHub: artesano.anosExperiencia,
      valoracionesPositivas: artesano.totalResenas,
      ventasRealizadas: artesano.totalVentas,
      descripcion: artesano.descripcion,
      etiquetas: artesano.especialidades,
      colecciones: artesano.especialidades,
      productos: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(oscuro),
      body: Row(children: [

        // ── CONTENIDO PRINCIPAL ──────────────────────────────
        Expanded(
          child: Column(children: [

            // ── CUERPO (TopBar eliminado desde aquí) ─────────
            Expanded(
              child: Row(children: [

                // ── PANEL IZQUIERDO: lista ──
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
                        onCategoria: (v) => setState(() {
                          _categoriaSeleccionada = v;
                          // 🔌 _recargarArtesanos()
                        }),
                        onProvincia: (v) => setState(() {
                          _provinciaSeleccionada = v;
                          // 🔌 _recargarArtesanos()
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Grid 4 columnas
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

                // ── PANEL DERECHO: perfil ──
                if (_artesanosFiltrados.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: PanelPerfilArtesano(
                      key: ValueKey(_artesanosFiltrados[_artesanoSeleccionado].id),
                      artesano: _artesanosFiltrados[_artesanoSeleccionado],
                      alVerProductos: () {
                        final artesanoActual = _artesanosFiltrados[_artesanoSeleccionado];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PantallaPerfilArtesano(
                              artesano: _convertirAModeloArtesano(artesanoActual),
                            ),
                          ),
                        );
                      },
                      alEnviarMensaje: () {
                        // 🔌 Navigator.pushNamed(context, '/chat',
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

// ── Widgets auxiliares de la pantalla ───────────────────────────────────

class _EncabezadoSeccion extends StatelessWidget {
  final bool oscuro;
  const _EncabezadoSeccion({required this.oscuro});

  @override
  Widget build(BuildContext context) {
    // 🔌 totalArtesanos viene de GET /api/artesanos/stats
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
        Text('Conoce a los talentosos artesanos que mantienen vivas\nnuestras tradiciones y cultura panameña.',
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
            Text('+250', // 🔌 reemplazar con total del backend
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
      // Dropdown categoría — 🔌 GET /api/categorias
      _DropdownFiltro(
        valor: categoriaSeleccionada,
        opciones: _categorias,
        onSeleccionar: onCategoria,
        oscuro: oscuro,
      ),
      const SizedBox(width: 8),
      // Dropdown provincia — 🔌 GET /api/provincias
      _DropdownFiltro(
        valor: provinciaSeleccionada,
        opciones: _provincias,
        onSeleccionar: onProvincia,
        oscuro: oscuro,
      ),
      const SizedBox(width: 8),
      // Botón más filtros
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
          Text('Más filtros',
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