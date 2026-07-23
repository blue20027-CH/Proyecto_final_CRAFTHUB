import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/comprador/tarjeta_producto_perfil.dart';
import '../../widgets/comprador/selector_coleccion.dart';
import '../../services/api_service.dart';
import '../../core/i18n/i18n.dart';

// Modelo de datos del artesano
// TODO: reemplazar con tu modelo real desde FastAPI
class ModeloArtesano {
  final String nombre;
  final String specialty; // Cambiado internamente si es necesario o manteniendo la interfaz
  final String especialidad;
  final String ubicacion;
  final String fotoUrl;
  final String bannerUrl;
  final double calificacion;
  final int totalResenas;
  final bool verificado;
  final int totalProductos;
  final int anosEnCraftHub;
  final int valoracionesPositivas;
  final int ventasRealizadas;
  final String descripcion;
  final List<String> etiquetas;
  final List<String> colecciones;
  final List<ModeloProductoResumen> productos;

  const ModeloArtesano({
    required this.nombre,
    required this.specialty,
    required this.especialidad,
    required this.ubicacion,
    required this.fotoUrl,
    required this.bannerUrl,
    required this.calificacion,
    required this.totalResenas,
    required this.verificado,
    required this.totalProductos,
    required this.anosEnCraftHub,
    required this.valoracionesPositivas,
    required this.ventasRealizadas,
    required this.descripcion,
    required this.etiquetas,
    required this.colecciones,
    required this.productos,
  });
}

class ModeloProductoResumen {
  final String id;
  final String nombre;
  final String precio;
  final String imagenUrl;
  final String coleccion;

  const ModeloProductoResumen({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    required this.coleccion,
  });

  // Mapea el producto crudo que devuelve GET /artesanos/{nombre} (campo "productos").
  factory ModeloProductoResumen.fromJson(Map<String, dynamic> json) {
    final precio = double.tryParse((json['precio'] ?? 0).toString()) ?? 0;
    return ModeloProductoResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      precio: '\$${precio.toStringAsFixed(2)}',
      imagenUrl: (json['imagen_url'] ?? json['imagen'] ?? json['img'] ?? '').toString(),
      coleccion: (json['categoria'] ?? 'General').toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────
class PantallaPerfilArtesano extends StatefulWidget {
  final ModeloArtesano artesano;
  // Cuando es tu propio perfil (te lo abrió el sidebar del vendedor), se ve
  // exactamente igual a como lo ve un comprador, pero con un botón de
  // "Editar perfil" en vez de "Enviar mensaje"/"Seguir".
  final bool esPropio;
  final VoidCallback? onEditar;
  final VoidCallback? onEnviarMensaje;

  const PantallaPerfilArtesano({
    super.key,
    required this.artesano,
    this.esPropio = false,
    this.onEditar,
    this.onEnviarMensaje,
  });

  @override
  State<PantallaPerfilArtesano> createState() => _PantallaPerfilArtesanoState();
}

class _PantallaPerfilArtesanoState extends State<PantallaPerfilArtesano> {
  String? _coleccionSeleccionada;
  final Set<String> _favoritos = {};

  @override
  void initState() {
    super.initState();
    // Cuenta como una visita real al perfil (dashboard del vendedor).
    ApiService.registrarVisitaPerfil(widget.artesano.nombre);
  }

  List<ModeloProductoResumen> get _productosFiltrados {
    if (_coleccionSeleccionada == null) return widget.artesano.productos;
    return widget.artesano.productos
        .where((p) => p.coleccion == _coleccionSeleccionada)
        .toList();
  }

  String get _tituloProductos {
    final nombre = widget.artesano.nombre.split(' ').first;
    if (_coleccionSeleccionada == null) {
      return '${tr(context, 'comprador_secundario.productos_de')} $nombre';
    }
    return _coleccionSeleccionada!;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artesano;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(esOscuro),
      body: Column(
        children: [
          // ── BANNER + INFO SUPERIOR ──────────────────────────────────
          _SeccionBanner(
            artesano: a,
            onVolver: () => Navigator.maybePop(context),
            esPropio: widget.esPropio,
            onEditar: widget.onEditar,
            onEnviarMensaje: widget.onEnviarMensaje,
          ),

          // ── CUERPO: stats + contenido ───────────────────────────────
          _SeccionEstadisticas(artesano: a),

          // ── CONTENIDO PRINCIPAL ─────────────────────────────────────
          // El panel izquierdo queda fijo en pantalla (no forma parte del
          // scroll) para que la info del artesano no "desaparezca" mientras
          // se navega por su catálogo de productos, que sí se desplaza
          // dentro de su propio scroll independiente.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: SingleChildScrollView(child: _PanelIzquierdo(artesano: a)),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _PanelProductos(
                        tituloProductos: _tituloProductos,
                        totalProductos: _productosFiltrados.length,
                        colecciones: a.colecciones,
                        coleccionSeleccionada: _coleccionSeleccionada,
                        productos: _productosFiltrados,
                        favoritos: _favoritos,
                        alSeleccionarColeccion: (c) =>
                            setState(() => _coleccionSeleccionada = c),
                        alToggleFavorito: (id) => setState(() {
                          _favoritos.contains(id)
                              ? _favoritos.remove(id)
                              : _favoritos.add(id);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN BANNER
// ─────────────────────────────────────────────────────────────
class _SeccionBanner extends StatelessWidget {
  final ModeloArtesano artesano;
  final VoidCallback onVolver;
  final bool esPropio;
  final VoidCallback? onEditar;
  final VoidCallback? onEnviarMensaje;

  const _SeccionBanner({
    required this.artesano,
    required this.onVolver,
    this.esPropio = false,
    this.onEditar,
    this.onEnviarMensaje,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    // Nuevo layout: banner limpio de 220px (para que se aprecie de verdad),
    // tarjeta debajo con el avatar sobresaliendo hacia el banner, y botones
    // apilados verticalmente a la derecha.
    return Column(
      children: [
        // ── BANNER LIMPIO ─────────────────────────────────────────
        SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                artesano.bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CraftHubColors.vinoTinto.withValues(alpha: 0.35),
                        CraftHubColors.vinoTinto.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              // Velo sutil en la parte superior para que el botón volver
              // se lea bien sin oscurecer el banner completo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 24,
                child: _BotonVolver(onVolver: onVolver),
              ),
            ],
          ),
        ),

        // ── TARJETA DE IDENTIDAD (avatar sobresale hacia el banner) ─
        // Margen superior negativo para que "muerda" el final del banner
        // y el avatar quede pisado entre banner y tarjeta.
        Container(
              margin: const EdgeInsets.fromLTRB(24, -55, 24, 0),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: BoxDecoration(
                color: CraftHubColors.panel(esOscuro),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CraftHubColors.borde(esOscuro)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: esOscuro ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar sobresale ~50px hacia el banner
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: SizedBox(
                      height: 116,
                      width: 116,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: CraftHubColors.panel(esOscuro), width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                artesano.fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: CraftHubColors.borde(esOscuro),
                                  child: Icon(
                                    Icons.person,
                                    size: 56,
                                    color: CraftHubColors.textoSecundario(esOscuro),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (artesano.verificado)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A843),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: CraftHubColors.panel(esOscuro), width: 2),
                                ),
                                child: const Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Info: nombre, especialidad, ubicación, rating + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                artesano.nombre,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: CraftHubColors.textoPrincipal(esOscuro),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (artesano.verificado) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded, size: 20, color: Color(0xFFD4A843)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artesano.especialidad,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: CraftHubColors.textoSecundario(esOscuro),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 18,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_outlined, size: 15, color: CraftHubColors.textoSecundario(esOscuro)),
                                const SizedBox(width: 4),
                                Text(
                                  artesano.ubicacion,
                                  style: TextStyle(fontSize: 12.5, color: CraftHubColors.textoSecundario(esOscuro)),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD4A843)),
                                const SizedBox(width: 4),
                                Text(
                                  '${artesano.calificacion} (${artesano.totalResenas} ${tr(context, 'comprador_secundario.resenas_label')})',
                                  style: TextStyle(fontSize: 12.5, color: CraftHubColors.textoSecundario(esOscuro)),
                                ),
                              ],
                            ),
                            if (artesano.verificado)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A843).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  tr(context, 'comprador_secundario.artesana_verificada_badge'),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600,
                                    color: Color(0xFFB8892E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Botones apilados verticalmente
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: esPropio
                        ? [
                            _BotonAccion(
                              texto: tr(context, 'comprador_secundario.editar_perfil'),
                              icono: Icons.edit_outlined,
                              esPrimario: true,
                              alPresionar: onEditar ?? () {},
                            ),
                          ]
                        : [
                            _BotonAccion(
                              texto: tr(context, 'comprador_secundario.enviar_mensaje'),
                              icono: Icons.chat_bubble_outline_rounded,
                              esPrimario: true,
                              alPresionar: () {
                                Navigator.maybePop(context);
                                onEnviarMensaje?.call();
                              },
                            ),
                            const SizedBox(height: 10),
                            _BotonAccion(
                              texto: tr(context, 'comprador_secundario.seguir_artesana'),
                              icono: Icons.favorite_border_rounded,
                              esPrimario: false,
                              alPresionar: () {},
                            ),
                          ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN VOLVER
// ─────────────────────────────────────────────────────────────
class _BotonVolver extends StatefulWidget {
  final VoidCallback onVolver;
  const _BotonVolver({required this.onVolver});

  @override
  State<_BotonVolver> createState() => _BotonVolverState();
}

class _BotonVolverState extends State<_BotonVolver> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit:  (_) => setState(() => _sobre = false), // Corregido typo (_false = false)
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onVolver,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _sobre
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 16, color: CraftHubColors.textoClaro),
              const SizedBox(width: 6),
              Text(
                tr(context, 'comprador_secundario.volver'),
                style: const TextStyle(
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

// ─────────────────────────────────────────────────────────────
// BOTÓN ACCIÓN (Enviar mensaje / Seguir)
// ─────────────────────────────────────────────────────────────
class _BotonAccion extends StatefulWidget {
  final String texto;
  final IconData icono;
  final bool esPrimario;
  final VoidCallback alPresionar;

  const _BotonAccion({
    required this.texto,
    required this.icono,
    required this.esPrimario,
    required this.alPresionar,
  });

  @override
  State<_BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<_BotonAccion> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = widget.esPrimario
        ? (_sobre ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto)
        : (_sobre ? (esOscuro ? CraftHubColors.panelOscuro2 : Colors.grey[50]!) : CraftHubColors.panel(esOscuro));
    final colorTexto = widget.esPrimario ? Colors.white : CraftHubColors.textoPrincipal(esOscuro);
    final colorBorde = widget.esPrimario ? Colors.transparent : CraftHubColors.borde(esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit:  (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 160, 
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorBorde, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icono, size: 15, color: colorTexto),
              const SizedBox(width: 6),
              Text(
                widget.texto,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorTexto,
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
// SECCIÓN ESTADÍSTICAS
// ─────────────────────────────────────────────────────────────
class _SeccionEstadisticas extends StatelessWidget {
  final ModeloArtesano artesano;
  const _SeccionEstadisticas({required this.artesano});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(44, 12, 44, 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        // Corregido: border debe estar contenido obligatoriamente dentro de un BoxDecoration
        border: Border(
          bottom: BorderSide(color: CraftHubColors.borde(esOscuro), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, 
        children: [
          _StatNumerico(
              icono: Icons.inventory_2_outlined,
              valor: '${artesano.totalProductos}',
              etiqueta: tr(context, 'comprador_secundario.productos')),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.calendar_today_outlined,
              valor: '${artesano.anosEnCraftHub} ${tr(context, 'comprador_secundario.anos_palabra')}',
              etiqueta: tr(context, 'comprador_secundario.en_crafthub')),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.thumb_up_alt_outlined,
              valor: '${artesano.valoracionesPositivas}%',
              etiqueta: tr(context, 'comprador_secundario.valoraciones_positivas')),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.shopping_bag_outlined,
              valor: '${artesano.ventasRealizadas}',
              etiqueta: tr(context, 'comprador_secundario.ventas_realizadas')),
        ],
      ),
    );
  }
}

class _StatNumerico extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _StatNumerico({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: 20, color: CraftHubColors.textoSecundario(esOscuro).withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(esOscuro),
              ),
            ),
            Text(
              etiqueta,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: CraftHubColors.textoSecundario(esOscuro),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANEL IZQUIERDO
// ─────────────────────────────────────────────────────────────
class _PanelIzquierdo extends StatelessWidget {
  final ModeloArtesano artesano;
  const _PanelIzquierdo({required this.artesano});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final primerNombre = artesano.nombre.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CraftHubColors.vinoTintoSuave,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline_rounded, size: 16, color: CraftHubColors.vinoTinto),
            ),
            const SizedBox(width: 10),
            Text(
              '${tr(context, 'comprador_secundario.sobre')} $primerNombre',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(esOscuro),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            artesano.descripcion,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.6,
              color: CraftHubColors.textoSecundario(esOscuro),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: CraftHubColors.borde(esOscuro), height: 1),
          const SizedBox(height: 18),
          Text(
            tr(context, 'comprador_secundario.especialidades_titulo'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: CraftHubColors.textoSecundario(esOscuro),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: artesano.etiquetas
                .map((e) => _EtiquetaChip(texto: e))
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: esOscuro ? CraftHubColors.panelOscuro2 : const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CraftHubColors.vinoTinto.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CraftHubColors.vinoTinto.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, size: 17, color: CraftHubColors.vinoTinto),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'comprador_secundario.envios_todo_panama'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CraftHubColors.textoPrincipal(esOscuro),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(context, 'comprador_secundario.entregas_rapidas_seguras'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: CraftHubColors.textoSecundario(esOscuro),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EtiquetaChip extends StatelessWidget {
  final String texto;
  const _EtiquetaChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esOscuro ? CraftHubColors.panelOscuro2 : const Color(0xFFF4EFEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: CraftHubColors.textoPrincipal(esOscuro),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANEL PRODUCTOS
// ─────────────────────────────────────────────────────────────
class _PanelProductos extends StatelessWidget {
  final String tituloProductos;
  final int totalProductos;
  final List<String> colecciones;
  final String? coleccionSeleccionada;
  final List<ModeloProductoResumen> productos;
  final Set<String> favoritos;
  final ValueChanged<String?> alSeleccionarColeccion;
  final ValueChanged<String> alToggleFavorito;

  const _PanelProductos({
    required this.tituloProductos,
    required this.totalProductos,
    required this.colecciones,
    required this.coleccionSeleccionada,
    required this.productos,
    required this.favoritos,
    required this.alSeleccionarColeccion,
    required this.alToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tituloProductos,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(esOscuro),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: esOscuro ? CraftHubColors.panelOscuro2 : const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalProductos ${tr(context, 'comprador_secundario.productos_palabra')}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
            ),
            const Spacer(),
            SelectorColeccion(
              colecciones: colecciones,
              coleccionSeleccionada: coleccionSeleccionada,
              alSeleccionar: alSeleccionarColeccion,
            ),
          ],
        ),
        const SizedBox(height: 20),

        productos.isEmpty
            ? SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    tr(context, 'comprador_secundario.sin_productos_en_coleccion'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: CraftHubColors.textoSecundario(esOscuro),
                    ),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82, 
                ),
                itemCount: productos.length,
                itemBuilder: (_, i) {
                  final p = productos[i];
                  return TarjetaProductoPerfil(
                    imagenUrl: p.imagenUrl,
                    nombre: p.nombre,
                    precio: p.precio,
                    esFavorito: favoritos.contains(p.id),
                    alToggleFavorito: () => alToggleFavorito(p.id),
                    alPresionar: () {},
                  );
                },
              ),
      ],
    );
  }
}