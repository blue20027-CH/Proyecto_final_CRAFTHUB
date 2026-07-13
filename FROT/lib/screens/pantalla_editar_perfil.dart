// lib/screens/pantalla_editar_perfil.dart
// Pantalla compartida (comprador y vendedor) para editar el perfil: banner,
// foto de perfil, descripción, provincia/ubicación y teléfono.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/provincias_panama.dart';
import '../models/artesano_modelo.dart' show bannerPorCategoria;
import '../services/api_service.dart';

const List<String> _categoriasArtesano = [
  'Vestir', 'Artesanía', 'Muebles', 'Joyería', 'Alimentos', 'Accesorios', 'Calzado',
];

class PantallaEditarPerfil extends StatefulWidget {
  final String userId;
  const PantallaEditarPerfil({super.key, required this.userId});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  final _ctrlDescripcion = TextEditingController();
  final _ctrlUbicacion = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  String? _provincia;
  String? _categoria;

  String _nombre = '';
  String _email = '';
  String _fotoUrl = '';
  String _bannerUrl = '';
  String _modo = 'comprador';

  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  bool _subiendoBanner = false;
  String? _error;
  bool _huboExito = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _ctrlDescripcion.dispose();
    _ctrlUbicacion.dispose();
    _ctrlTelefono.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (!mounted) return;
      setState(() {
        _nombre = (perfil['nombre'] ?? 'Usuario CraftHub').toString();
        _email = (perfil['email'] ?? '').toString();
        _fotoUrl = (perfil['foto'] ?? '').toString();
        _bannerUrl = (perfil['foto_portada'] ?? '').toString();
        _ctrlDescripcion.text = (perfil['descripcion'] ?? '').toString();
        _ctrlUbicacion.text = (perfil['ubicacion'] ?? '').toString();
        _ctrlTelefono.text = (perfil['telefono'] ?? '').toString();
        _modo = (perfil['modo'] ?? 'comprador').toString();
        final provinciaActual = (perfil['provincia'] ?? '').toString();
        _provincia = kProvinciasPanama.contains(provinciaActual) ? provinciaActual : null;
        final categoriaActual = (perfil['categoria'] ?? '').toString();
        _categoria = _categoriasArtesano.contains(categoriaActual) ? categoriaActual : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar tu perfil: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarFoto({required bool esBanner}) async {
    FilePickerResult? resultado;
    try {
      resultado = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el selector de imágenes: ${e.toString().replaceAll('Exception: ', '')}')),
      );
      return;
    }
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.single;
    final bytes = archivo.bytes;
    if (bytes == null) return;

    setState(() {
      if (esBanner) {
        _subiendoBanner = true;
      } else {
        _subiendoFoto = true;
      }
    });
    try {
      final url = await ApiService.subirFotoPerfil(
        widget.userId,
        bytes,
        archivo.name,
        tipo: esBanner ? 'portada' : 'foto',
      );
      if (!mounted) return;
      setState(() {
        if (esBanner) {
          _bannerUrl = url;
        } else {
          _fotoUrl = url;
        }
        _huboExito = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la imagen: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subiendoBanner = false;
          _subiendoFoto = false;
        });
      }
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ApiService.actualizarPerfil(widget.userId, {
        if (_modo == 'vendedor') 'descripcion': _ctrlDescripcion.text.trim(),
        'ubicacion': _ctrlUbicacion.text.trim(),
        if (_provincia != null) 'provincia': _provincia,
        if (_categoria != null) 'categoria': _categoria,
        'telefono': _ctrlTelefono.text.trim(),
      });
      if (!mounted) return;
      setState(() => _huboExito = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'No se pudo guardar: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // Si el vendedor no ha subido su propia portada, usamos un banner por
  // defecto según su categoría (misma lógica que ArtesanoModelo.bannerEfectivo),
  // en vez de dejarlo vacío o solo con un ícono de "agregar imagen".
  String get _bannerEfectivo {
    if (_bannerUrl.isNotEmpty) return _bannerUrl;
    if (_modo == 'vendedor' && _categoria != null) return bannerPorCategoria(_categoria!);
    return '';
  }

  String _iniciales() {
    final partes = _nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? 'CH' : texto;
  }

  InputDecoration _decoracion(bool esOscuro, {required IconData icono, String? hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icono, size: 19, color: CraftHubColors.vinoTinto),
      filled: true,
      fillColor: esOscuro ? const Color(0xFF262019) : const Color(0xFFFAF7F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: esOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE8DED4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: esOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE8DED4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPanel = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorBorde = esOscuro ? const Color(0xFF2E2E2E) : const Color(0xFFEDE8E2);

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(esOscuro),
      appBar: AppBar(
        backgroundColor: CraftHubColors.fondo(esOscuro),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: CraftHubColors.textoPrincipal(esOscuro)),
          onPressed: () => Navigator.pop(context, _huboExito),
        ),
        title: Text('Editar perfil',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(esOscuro))),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Banner + avatar ─────────────────────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _AreaImagen(
                            alTocar: _subiendoBanner ? null : () => _cambiarFoto(esBanner: true),
                            subiendo: _subiendoBanner,
                            child: Container(
                              width: double.infinity,
                              height: 176,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: _bannerEfectivo.isEmpty
                                    ? LinearGradient(
                                        colors: [
                                          CraftHubColors.vinoTinto.withValues(alpha: 0.18),
                                          CraftHubColors.vinoTinto.withValues(alpha: 0.06),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                image: _bannerEfectivo.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(_bannerEfectivo), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _bannerEfectivo.isEmpty && !_subiendoBanner
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined,
                                              size: 30, color: CraftHubColors.vinoTinto.withValues(alpha: 0.6)),
                                          const SizedBox(height: 6),
                                          Text('Agregar foto de portada',
                                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5,
                                                  color: CraftHubColors.vinoTinto.withValues(alpha: 0.7))),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 14,
                            bottom: 12,
                            child: _BotonCamara(
                              onTap: _subiendoBanner ? null : () => _cambiarFoto(esBanner: true),
                              etiqueta: 'Cambiar portada',
                            ),
                          ),
                          Positioned(
                            left: 24,
                            bottom: -44,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _AreaImagen(
                                  alTocar: _subiendoFoto ? null : () => _cambiarFoto(esBanner: false),
                                  subiendo: _subiendoFoto,
                                  circular: true,
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: CraftHubColors.fondo(esOscuro), width: 4),
                                      color: CraftHubColors.vinoTintoSuave,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                                      ],
                                      image: _fotoUrl.isNotEmpty
                                          ? DecorationImage(image: NetworkImage(_fotoUrl), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: _fotoUrl.isEmpty && !_subiendoFoto
                                        ? Center(
                                            child: Text(_iniciales(),
                                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 24,
                                                    fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: _BotonCamara(
                                    pequeno: true,
                                    onTap: _subiendoFoto ? null : () => _cambiarFoto(esBanner: false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 56),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nombre,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 21, fontWeight: FontWeight.w700,
                                    color: CraftHubColors.textoPrincipal(esOscuro))),
                            if (_email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(_email,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                      color: CraftHubColors.textoSecundario(esOscuro))),
                            ],
                            const SizedBox(height: 22),

                            // ── Tarjeta con los campos editables ─────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorPanel,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorBorde),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_modo == 'vendedor') ...[
                                    _EtiquetaCampo(icono: Icons.description_outlined, texto: 'Descripción', esOscuro: esOscuro),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _ctrlDescripcion,
                                      maxLines: 3,
                                      decoration: _decoracion(esOscuro,
                                          icono: Icons.description_outlined,
                                          hint: 'Cuéntale a tus clientes sobre ti o tu taller...'),
                                    ),
                                    const SizedBox(height: 20),

                                    _EtiquetaCampo(icono: Icons.category_outlined, texto: 'Categoría principal', esOscuro: esOscuro),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _categoria,
                                      decoration: _decoracion(esOscuro, icono: Icons.category_outlined, hint: 'Selecciona tu categoría'),
                                      items: _categoriasArtesano
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (v) => setState(() => _categoria = v),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  _EtiquetaCampo(icono: Icons.map_outlined, texto: 'Provincia / comarca', esOscuro: esOscuro),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _provincia,
                                    decoration: _decoracion(esOscuro, icono: Icons.map_outlined, hint: 'Selecciona tu provincia'),
                                    items: kProvinciasPanama
                                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _provincia = v),
                                  ),
                                  const SizedBox(height: 20),

                                  _EtiquetaCampo(icono: Icons.location_on_outlined, texto: 'Ciudad / dirección (opcional)', esOscuro: esOscuro),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _ctrlUbicacion,
                                    decoration: _decoracion(esOscuro, icono: Icons.location_on_outlined, hint: 'Ej. David, Chiriquí'),
                                  ),
                                  const SizedBox(height: 20),

                                  _EtiquetaCampo(icono: Icons.phone_outlined, texto: 'Teléfono', esOscuro: esOscuro),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _ctrlTelefono,
                                    keyboardType: TextInputType.phone,
                                    decoration: _decoracion(esOscuro, icono: Icons.phone_outlined, hint: '+507 6000-0000'),
                                  ),
                                ],
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.redAccent)),
                            ],
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _guardando ? null : _guardar,
                                icon: _guardando
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_rounded, size: 19),
                                label: Text(_guardando ? 'Guardando...' : 'Guardar cambios',
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CraftHubColors.vinoTinto,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _EtiquetaCampo extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool esOscuro;
  const _EtiquetaCampo({required this.icono, required this.texto, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 14, color: CraftHubColors.vinoTinto),
        const SizedBox(width: 6),
        Text(texto,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600,
                color: CraftHubColors.textoSecundario(esOscuro))),
      ],
    );
  }
}

// Envuelve el banner/avatar con un overlay de hover + spinner de subida,
// para que se sienta interactivo (no solo una imagen estática).
class _AreaImagen extends StatefulWidget {
  final Widget child;
  final VoidCallback? alTocar;
  final bool subiendo;
  final bool circular;
  const _AreaImagen({
    required this.child,
    required this.alTocar,
    required this.subiendo,
    this.circular = false,
  });

  @override
  State<_AreaImagen> createState() => _AreaImagenState();
}

class _AreaImagenState extends State<_AreaImagen> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alTocar,
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_hover || widget.subiendo)
              ClipRRect(
                borderRadius: widget.circular ? BorderRadius.circular(100) : BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: widget.subiendo ? 0.4 : 0.18),
                  child: widget.subiendo
                      ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BotonCamara extends StatefulWidget {
  final VoidCallback? onTap;
  final bool pequeno;
  final String? etiqueta;
  const _BotonCamara({required this.onTap, this.pequeno = false, this.etiqueta});

  @override
  State<_BotonCamara> createState() => _BotonCamaraState();
}

class _BotonCamaraState extends State<_BotonCamara> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (widget.etiqueta != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _hover ? 0.75 : 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.etiqueta!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.pequeno ? 28 : 32,
          height: widget.pequeno ? 28 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(Icons.photo_camera_outlined, size: widget.pequeno ? 13 : 15, color: Colors.white),
        ),
      ),
    );
  }
}
