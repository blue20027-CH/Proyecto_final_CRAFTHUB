// lib/screens/comprador/pantalla_mi_perfil.dart
// Vista de "Mi perfil" para el comprador: solo lectura, con un botón para
// entrar a editarlo. No existe un perfil público de comprador (a diferencia
// del artesano), así que esta es una vista propia simple.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../pantalla_editar_perfil.dart';
import '../../services/api_service.dart';
import '../../core/i18n/i18n.dart';

class PantallaMiPerfilComprador extends StatefulWidget {
  final String userId;
  const PantallaMiPerfilComprador({super.key, required this.userId});

  @override
  State<PantallaMiPerfilComprador> createState() => _PantallaMiPerfilCompradorState();
}

class _PantallaMiPerfilCompradorState extends State<PantallaMiPerfilComprador> {
  bool _cargando = true;
  String _nombre = '';
  String _email = '';
  String _fotoUrl = '';
  String _bannerUrl = '';
  String _descripcion = '';
  String _provincia = '';
  String _ubicacion = '';
  String _telefono = '';

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
        _nombre = (perfil['nombre'] ?? tr(context, 'comprador_secundario.usuario_crafthub')).toString();
        _email = (perfil['email'] ?? '').toString();
        _fotoUrl = (perfil['foto'] ?? '').toString();
        _bannerUrl = (perfil['foto_portada'] ?? '').toString();
        _descripcion = (perfil['descripcion'] ?? '').toString();
        _provincia = (perfil['provincia'] ?? '').toString();
        _ubicacion = (perfil['ubicacion'] ?? '').toString();
        _telefono = (perfil['telefono'] ?? '').toString();
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

  String _iniciales() {
    final partes = _nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? 'UC' : texto;
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
        title: Text(tr(context, 'comprador_secundario.mi_perfil'),
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
                      // ── Banner + avatar (solo lectura) ────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: _bannerUrl.isEmpty
                                  ? LinearGradient(
                                      colors: [
                                        CraftHubColors.vinoTinto.withValues(alpha: 0.18),
                                        CraftHubColors.vinoTinto.withValues(alpha: 0.06),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              image: _bannerUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(_bannerUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                          ),
                          Positioned(
                            left: 24,
                            bottom: -40,
                            child: Container(
                              width: 84,
                              height: 84,
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
                              child: _fotoUrl.isEmpty
                                  ? Center(
                                      child: Text(_iniciales(),
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 22,
                                              fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 52),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_nombre,
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700,
                                              color: CraftHubColors.textoPrincipal(esOscuro))),
                                      if (_email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(_email,
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                                color: CraftHubColors.textoSecundario(esOscuro))),
                                      ],
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _editarPerfil,
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: Text(tr(context, 'comprador_secundario.editar_perfil'),
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CraftHubColors.vinoTinto,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

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
                                  _FilaInfo(
                                    icono: Icons.description_outlined,
                                    etiqueta: tr(context, 'comprador_secundario.descripcion'),
                                    valor: _descripcion.isEmpty ? tr(context, 'comprador_secundario.sin_descripcion_todavia') : _descripcion,
                                    esOscuro: esOscuro,
                                  ),
                                  const Divider(height: 28),
                                  _FilaInfo(
                                    icono: Icons.map_outlined,
                                    etiqueta: tr(context, 'comprador_secundario.provincia_comarca'),
                                    valor: _provincia.isEmpty ? tr(context, 'comprador_secundario.sin_especificar') : _provincia,
                                    esOscuro: esOscuro,
                                  ),
                                  const Divider(height: 28),
                                  _FilaInfo(
                                    icono: Icons.location_on_outlined,
                                    etiqueta: tr(context, 'comprador_secundario.ciudad_direccion'),
                                    valor: _ubicacion.isEmpty ? tr(context, 'comprador_secundario.sin_especificar') : _ubicacion,
                                    esOscuro: esOscuro,
                                  ),
                                  const Divider(height: 28),
                                  _FilaInfo(
                                    icono: Icons.phone_outlined,
                                    etiqueta: tr(context, 'comprador_secundario.telefono'),
                                    valor: _telefono.isEmpty ? tr(context, 'comprador_secundario.sin_especificar') : _telefono,
                                    esOscuro: esOscuro,
                                  ),
                                ],
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

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool esOscuro;
  const _FilaInfo({required this.icono, required this.etiqueta, required this.valor, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: CraftHubColors.vinoTinto),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoSecundario(esOscuro))),
              const SizedBox(height: 3),
              Text(valor,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5,
                      color: CraftHubColors.textoPrincipal(esOscuro))),
            ],
          ),
        ),
      ],
    );
  }
}
