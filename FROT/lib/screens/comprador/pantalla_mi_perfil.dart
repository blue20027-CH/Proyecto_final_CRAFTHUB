// lib/screens/comprador/pantalla_mi_perfil.dart
// "Mi perfil" del comprador: además de los datos de solo lectura (con botón
// para editarlos), funciona como pantalla de Configuración — historial de
// facturas, apariencia/idioma, métodos de pago (tarjetas guardadas) y
// seguridad (cambio de contraseña). No existe un perfil público de
// comprador (a diferencia del artesano), así que esta es la vista propia.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart' show GestorTema;
import '../../services/api_service.dart';
import '../../widgets/comprador/seccion_historial_pedidos.dart';
import '../../widgets/comprador/seccion_metodos_pago.dart';
import '../../widgets/comprador/seccion_seguridad.dart';
import '../../widgets/comprador/tarjeta_seccion.dart';
import '../pantalla_editar_perfil.dart';

/// Textos de la sección "Preferencias" en es/en — demostración de que el
/// idioma guardado en el perfil (`perfil['idioma']`) puede reetiquetar esta
/// pantalla. No es un framework de traducción para toda la app.
const Map<String, Map<String, String>> _textos = {
  'es': {
    'titulo': 'Mi perfil',
    'editar': 'Editar perfil',
    'preferencias': 'Preferencias',
    'preferenciasSub': 'Personaliza tu experiencia en CraftHub.',
    'tema': 'Tema',
    'claro': 'Claro',
    'oscuro': 'Oscuro',
    'idioma': 'Idioma',
    'sinEspecificar': 'Sin especificar',
    'cuentaActiva': 'Cuenta activa',
  },
  'en': {
    'titulo': 'My profile',
    'editar': 'Edit profile',
    'preferencias': 'Preferences',
    'preferenciasSub': 'Personalize your CraftHub experience.',
    'tema': 'Theme',
    'claro': 'Light',
    'oscuro': 'Dark',
    'idioma': 'Language',
    'sinEspecificar': 'Not specified',
    'cuentaActiva': 'Active account',
  },
};

class PantallaMiPerfilComprador extends StatefulWidget {
  final String userId;
  const PantallaMiPerfilComprador({super.key, required this.userId});

  @override
  State<PantallaMiPerfilComprador> createState() => _PantallaMiPerfilCompradorState();
}

class _PantallaMiPerfilCompradorState extends State<PantallaMiPerfilComprador> {
  bool _cargando = true;
  bool _subiendoFoto = false;
  Map<String, dynamic> _perfil = {};
  String _nombre = '';
  String _email = '';
  String _fotoUrl = '';
  String _provincia = '';
  String _ubicacion = '';
  String _telefono = '';
  String _idioma = 'es';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _nombre = (perfil['nombre'] ?? 'Usuario CraftHub').toString();
        _email = (perfil['email'] ?? '').toString();
        _fotoUrl = (perfil['foto'] ?? '').toString();
        _provincia = (perfil['provincia'] ?? '').toString();
        _ubicacion = (perfil['ubicacion'] ?? '').toString();
        _telefono = (perfil['telefono'] ?? '').toString();
        _idioma = (perfil['idioma'] ?? 'es').toString() == 'en' ? 'en' : 'es';
      });
    } catch (e) {
      debugPrint('Error cargando mi perfil: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editarPerfil() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaEditarPerfil(userId: widget.userId)),
    );
    if (actualizado == true) _cargarPerfil();
  }

  Future<void> _cambiarFoto() async {
    FilePickerResult? resultado;
    try {
      resultado = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el selector de imágenes: ${e.toString().replaceAll('Exception: ', '')}')),
      );
      return;
    }
    if (resultado == null || resultado.files.isEmpty) return;
    final bytes = resultado.files.single.bytes;
    if (bytes == null) return;

    setState(() => _subiendoFoto = true);
    try {
      final url = await ApiService.subirFotoPerfil(widget.userId, bytes, resultado.files.single.name, tipo: 'foto');
      if (!mounted) return;
      setState(() => _fotoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la foto: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _cambiarIdioma(String nuevo) async {
    final anterior = _idioma;
    setState(() => _idioma = nuevo);
    try {
      await ApiService.actualizarPerfil(widget.userId, {'idioma': nuevo});
    } catch (e) {
      if (!mounted) return;
      setState(() => _idioma = anterior);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el idioma: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  String _iniciales() {
    final partes = _nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? 'UC' : texto;
  }

  Map<String, String> get _t => _textos[_idioma]!;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final t = _t;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(esOscuro),
      appBar: AppBar(
        backgroundColor: CraftHubColors.fondo(esOscuro),
        elevation: 0,
        title: Text(t['titulo']!,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(esOscuro))),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
          : LayoutBuilder(
              builder: (context, constraints) {
                final anchoPantalla = constraints.maxWidth;
                final esAngosto = anchoPantalla < 480;
                final paddingHorizontal = anchoPantalla < 700 ? 16.0 : (anchoPantalla < 1100 ? 32.0 : 56.0);
                final anchoMaximo = anchoPantalla < 1400 ? double.infinity : 1300.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(paddingHorizontal, 20, paddingHorizontal, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: anchoMaximo),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TarjetaEncabezado(
                            esOscuro: esOscuro,
                            esAngosto: esAngosto,
                            nombre: _nombre,
                            email: _email,
                            fotoUrl: _fotoUrl,
                            provincia: _provincia,
                            ubicacion: _ubicacion,
                            telefono: _telefono,
                            iniciales: _iniciales(),
                            subiendoFoto: _subiendoFoto,
                            onCambiarFoto: _cambiarFoto,
                            onEditar: _editarPerfil,
                            textoEditar: t['editar']!,
                            textoCuentaActiva: t['cuentaActiva']!,
                            sinEspecificar: t['sinEspecificar']!,
                          ),

                          SeccionHistorialPedidos(userId: widget.userId, perfilComprador: _perfil, esOscuro: esOscuro),

                          TarjetaSeccion(
                            esOscuro: esOscuro,
                            icono: Icons.tune_rounded,
                            titulo: t['preferencias']!,
                            subtitulo: t['preferenciasSub']!,
                            colapsable: true,
                            child: esAngosto
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _FilaTema(esOscuro: esOscuro, etiqueta: t['tema']!),
                                      const SizedBox(height: 16),
                                      _FilaIdioma(esOscuro: esOscuro, etiqueta: t['idioma']!, idioma: _idioma, onCambiar: _cambiarIdioma),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _FilaTema(esOscuro: esOscuro, etiqueta: t['tema']!)),
                                      const SizedBox(width: 24),
                                      Expanded(child: _FilaIdioma(esOscuro: esOscuro, etiqueta: t['idioma']!, idioma: _idioma, onCambiar: _cambiarIdioma)),
                                    ],
                                  ),
                          ),

                          SeccionMetodosPago(userId: widget.userId, email: _email, esOscuro: esOscuro),

                          SeccionSeguridad(email: _email, esOscuro: esOscuro),

                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              'CraftHub © ${DateTime.now().year} · Hecho con ❤️ en Panamá',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(esOscuro)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TarjetaEncabezado extends StatelessWidget {
  final bool esOscuro;
  final bool esAngosto;
  final String nombre;
  final String email;
  final String fotoUrl;
  final String provincia;
  final String ubicacion;
  final String telefono;
  final String iniciales;
  final bool subiendoFoto;
  final VoidCallback onCambiarFoto;
  final VoidCallback onEditar;
  final String textoEditar;
  final String textoCuentaActiva;
  final String sinEspecificar;

  const _TarjetaEncabezado({
    required this.esOscuro,
    required this.esAngosto,
    required this.nombre,
    required this.email,
    required this.fotoUrl,
    required this.provincia,
    required this.ubicacion,
    required this.telefono,
    required this.iniciales,
    required this.subiendoFoto,
    required this.onCambiarFoto,
    required this.onEditar,
    required this.textoEditar,
    required this.textoCuentaActiva,
    required this.sinEspecificar,
  });

  @override
  Widget build(BuildContext context) {
    final ubicacionTexto = [provincia, ubicacion].where((s) => s.isNotEmpty).join(', ');

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CraftHubColors.vinoTinto,
            image: fotoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(fotoUrl), fit: BoxFit.cover) : null,
          ),
          alignment: Alignment.center,
          child: fotoUrl.isEmpty
              ? Text(iniciales, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: onCambiarFoto,
            child: Container(
              width: 26, height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CraftHubColors.panel(esOscuro),
                border: Border.all(color: CraftHubColors.borde(esOscuro)),
              ),
              child: subiendoFoto
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: CraftHubColors.vinoTinto))
                  : const Icon(Icons.photo_camera_outlined, size: 13, color: CraftHubColors.vinoTinto),
            ),
          ),
        ),
      ],
    );

    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(nombre,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700,
                      color: CraftHubColors.textoPrincipal(esOscuro))),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: textoCuentaActiva,
              child: Container(
                width: 16, height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: CraftHubColors.advertencia),
                child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FilaContacto(icono: Icons.mail_outline_rounded, texto: email.isEmpty ? sinEspecificar : email, esOscuro: esOscuro),
        const SizedBox(height: 4),
        _FilaContacto(icono: Icons.location_on_outlined, texto: ubicacionTexto.isEmpty ? sinEspecificar : ubicacionTexto, esOscuro: esOscuro),
        const SizedBox(height: 4),
        _FilaContacto(icono: Icons.phone_outlined, texto: telefono.isEmpty ? sinEspecificar : telefono, esOscuro: esOscuro),
      ],
    );

    final boton = OutlinedButton.icon(
      onPressed: onEditar,
      icon: const Icon(Icons.edit_outlined, size: 15, color: CraftHubColors.vinoTinto),
      label: Text(textoEditar, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: CraftHubColors.vinoTinto),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: esAngosto
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [avatar, const SizedBox(width: 16), Expanded(child: datos)]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: boton),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: datos),
                boton,
              ],
            ),
    );
  }
}

class _FilaContacto extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool esOscuro;
  const _FilaContacto({required this.icono, required this.texto, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 13, color: CraftHubColors.textoSecundario(esOscuro)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.textoSecundario(esOscuro))),
        ),
      ],
    );
  }
}

class _FilaTema extends StatelessWidget {
  final bool esOscuro;
  final String etiqueta;
  const _FilaTema({required this.esOscuro, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorTema>();
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(esOscuro))),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF262019) : const Color(0xFFFAF7F3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: CraftHubColors.borde(esOscuro)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BotonTema(
                esOscuro: esOscuro,
                icono: Icons.wb_sunny_outlined,
                activo: !gestor.esModoOscuro,
                onTap: gestor.esModoOscuro ? () => context.read<GestorTema>().alternarTema() : null,
              ),
              _BotonTema(
                esOscuro: esOscuro,
                icono: Icons.nightlight_outlined,
                activo: gestor.esModoOscuro,
                onTap: gestor.esModoOscuro ? null : () => context.read<GestorTema>().alternarTema(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonTema extends StatelessWidget {
  final bool esOscuro;
  final IconData icono;
  final bool activo;
  final VoidCallback? onTap;
  const _BotonTema({required this.esOscuro, required this.icono, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activo ? CraftHubColors.vinoTinto : Colors.transparent,
        ),
        child: Icon(icono, size: 16, color: activo ? Colors.white : CraftHubColors.textoSecundario(esOscuro)),
      ),
    );
  }
}

class _FilaIdioma extends StatelessWidget {
  final bool esOscuro;
  final String etiqueta;
  final String idioma;
  final ValueChanged<String> onCambiar;
  const _FilaIdioma({required this.esOscuro, required this.etiqueta, required this.idioma, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(esOscuro))),
        ),
        PopupMenuButton<String>(
          initialValue: idioma,
          onSelected: onCambiar,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'es', child: Text('Español', style: TextStyle(fontFamily: 'Poppins'))),
            PopupMenuItem(value: 'en', child: Text('English', style: TextStyle(fontFamily: 'Poppins'))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF262019) : const Color(0xFFFAF7F3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: CraftHubColors.borde(esOscuro)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                idioma == 'es'
                    ? Image.asset('assets/images/banderas/Panama.png', width: 16, height: 16, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.language, size: 15))
                    : const Icon(Icons.language, size: 15, color: CraftHubColors.vinoTinto),
                const SizedBox(width: 6),
                Text(idioma == 'es' ? 'Español' : 'English',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoPrincipal(esOscuro))),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: CraftHubColors.textoSecundario(esOscuro)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
