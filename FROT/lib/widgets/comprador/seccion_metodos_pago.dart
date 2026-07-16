// lib/widgets/comprador/seccion_metodos_pago.dart
// Sección "Métodos de pago" de Mi perfil/Configuración: lista las tarjetas
// guardadas del comprador (la "pasarela de pago" interna de CraftHub) y
// permite agregar/eliminar/marcar predeterminada. Toda escritura exige
// reautenticación con la contraseña real de la cuenta (mismo patrón que ya
// usa tarjetas_router.py en el backend).
// 🔌 GET/POST/DELETE/PATCH /api/tarjetas (BACK/CraftHub/tarjetas_router.py)
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../services/api_service.dart';
import '../campo_texto.dart';
import 'dialogo_confirmar_password.dart';
import 'tarjeta_seccion.dart';

const List<String> _marcasTarjeta = ['Visa', 'Mastercard', 'Amex', 'Otra'];

class SeccionMetodosPago extends StatefulWidget {
  final String userId;
  final String email;
  final bool esOscuro;
  const SeccionMetodosPago({super.key, required this.userId, required this.email, required this.esOscuro});

  @override
  State<SeccionMetodosPago> createState() => _SeccionMetodosPagoState();
}

class _SeccionMetodosPagoState extends State<SeccionMetodosPago> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _tarjetas = [];

  @override
  void initState() {
    super.initState();
    _cargarTarjetas();
  }

  Future<void> _cargarTarjetas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final tarjetas = await ApiService.getTarjetas(widget.userId);
      if (!mounted) return;
      setState(() => _tarjetas = tarjetas);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> tarjeta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'comprador_secundario.eliminar_tarjeta_confirmar_titulo'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(tr(context, 'comprador_secundario.eliminar_tarjeta_confirmar_mensaje').replaceAll('{ultimos4}', '${tarjeta['ultimos_4']}'),
            style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context, 'comprador_secundario.cancelar'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'comprador_secundario.eliminar'), style: const TextStyle(color: CraftHubColors.error)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final password = await mostrarDialogoConfirmarPassword(
      context,
      email: widget.email,
      titulo: tr(context, 'comprador_secundario.confirma_tu_contrasena'),
      mensaje: tr(context, 'comprador_secundario.password_msg_eliminar_tarjeta'),
    );
    if (password == null || !mounted) return;

    try {
      final mensaje = tr(context, 'comprador_secundario.tarjeta_eliminada');
      await ApiService.eliminarTarjeta(tarjeta['id'].toString(), email: widget.email, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      _cargarTarjetas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _marcarPredeterminada(Map<String, dynamic> tarjeta) async {
    final password = await mostrarDialogoConfirmarPassword(
      context,
      email: widget.email,
      titulo: tr(context, 'comprador_secundario.confirma_tu_contrasena'),
      mensaje: tr(context, 'comprador_secundario.password_msg_marcar_predeterminada'),
    );
    if (password == null || !mounted) return;

    try {
      await ApiService.marcarTarjetaPredeterminada(tarjeta['id'].toString(), email: widget.email, password: password);
      if (!mounted) return;
      _cargarTarjetas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _agregarTarjeta() async {
    final datos = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaAgregarTarjeta(esOscuro: widget.esOscuro),
    );
    if (datos == null || !mounted) return;

    final password = await mostrarDialogoConfirmarPassword(
      context,
      email: widget.email,
      titulo: tr(context, 'comprador_secundario.confirma_tu_contrasena'),
      mensaje: tr(context, 'comprador_secundario.password_msg_guardar_tarjeta'),
    );
    if (password == null || !mounted) return;

    try {
      final mensaje = tr(context, 'comprador_secundario.tarjeta_guardada');
      await ApiService.agregarTarjeta({
        'user_id': widget.userId,
        'email': widget.email,
        'password': password,
        ...datos,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      _cargarTarjetas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    return TarjetaSeccion(
      esOscuro: esOscuro,
      icono: Icons.credit_card_rounded,
      titulo: tr(context, 'comprador_secundario.metodos_pago_titulo'),
      subtitulo: tr(context, 'comprador_secundario.metodos_pago_subtitulo'),
      accion: ElevatedButton.icon(
        onPressed: _agregarTarjeta,
        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
        label: Text(tr(context, 'comprador_secundario.agregar_metodo'), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: CraftHubColors.vinoTinto,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      child: _cargando
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto, strokeWidth: 2)),
            )
          : _error != null
              ? Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.error))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tarjetas.isEmpty)
                      Text(tr(context, 'comprador_secundario.sin_tarjetas_guardadas'),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(esOscuro)))
                    else
                      ...List.generate(_tarjetas.length, (i) {
                        final t = _tarjetas[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: i == _tarjetas.length - 1 ? 0 : 10),
                          child: _FilaTarjeta(
                            esOscuro: esOscuro,
                            tarjeta: t,
                            onOpciones: () => _mostrarOpciones(t),
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: CraftHubColors.textoSecundario(esOscuro)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tr(context, 'comprador_secundario.info_pago_encriptada'),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: CraftHubColors.textoSecundario(esOscuro))),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  void _mostrarOpciones(Map<String, dynamic> tarjeta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tarjeta['predeterminada'] != true)
              ListTile(
                leading: const Icon(Icons.star_outline_rounded, color: CraftHubColors.vinoTinto),
                title: Text(tr(context, 'comprador_secundario.marcar_predeterminada'), style: const TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  Navigator.pop(context);
                  _marcarPredeterminada(tarjeta);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: CraftHubColors.error),
              title: Text(tr(context, 'comprador_secundario.eliminar_tarjeta_accion'), style: const TextStyle(fontFamily: 'Poppins', color: CraftHubColors.error)),
              onTap: () {
                Navigator.pop(context);
                _eliminar(tarjeta);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila plana de una tarjeta guardada: logo/ícono de marca, últimos 4
/// dígitos, insignia "Principal" si es la predeterminada, vencimiento y un
/// menú de opciones (marcar predeterminada / eliminar).
class _FilaTarjeta extends StatelessWidget {
  final bool esOscuro;
  final Map<String, dynamic> tarjeta;
  final VoidCallback onOpciones;
  const _FilaTarjeta({required this.esOscuro, required this.tarjeta, required this.onOpciones});

  Color get _colorMarca {
    switch (tarjeta['marca']) {
      case 'Visa':
        return const Color(0xFF1E5FAE);
      case 'Mastercard':
        return const Color(0xFFD9822B);
      case 'Amex':
        return const Color(0xFF12786A);
      default:
        return CraftHubColors.vinoTinto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final marca = (tarjeta['marca'] ?? 'Otra').toString();
    final ultimos4 = (tarjeta['ultimos_4'] ?? '----').toString();
    final mes = (tarjeta['mes_vencimiento'] as num?)?.toInt() ?? 1;
    final anio = (tarjeta['anio_vencimiento'] as num?)?.toInt() ?? 0;
    final predeterminada = tarjeta['predeterminada'] == true;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF262019) : const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _colorMarca.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.credit_card_rounded, size: 19, color: _colorMarca),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$marca •••• $ultimos4',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w600, color: colorTexto)),
                    if (predeterminada) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CraftHubColors.vinoTintoSuave,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tr(context, 'comprador_secundario.principal_badge'),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${tr(context, 'comprador_secundario.vence_prefijo')} ${mes.toString().padLeft(2, '0')}/${anio.toString().substring(anio.toString().length >= 2 ? anio.toString().length - 2 : 0)}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpciones,
            icon: Icon(Icons.more_vert_rounded, color: colorSec, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _HojaAgregarTarjeta extends StatefulWidget {
  final bool esOscuro;
  const _HojaAgregarTarjeta({required this.esOscuro});

  @override
  State<_HojaAgregarTarjeta> createState() => _HojaAgregarTarjetaState();
}

class _HojaAgregarTarjetaState extends State<_HojaAgregarTarjeta> {
  final _ctrlTitular = TextEditingController();
  final _ctrlUltimos4 = TextEditingController();
  final _ctrlAlias = TextEditingController();
  String _marca = _marcasTarjeta.first;
  int _mes = 1;
  int _anio = DateTime.now().year;
  bool _predeterminada = false;
  String? _error;

  @override
  void dispose() {
    _ctrlTitular.dispose();
    _ctrlUltimos4.dispose();
    _ctrlAlias.dispose();
    super.dispose();
  }

  void _guardar() {
    final ultimos4 = _ctrlUltimos4.text.trim();
    if (_ctrlTitular.text.trim().isEmpty) {
      setState(() => _error = tr(context, 'comprador_secundario.error_nombre_titular'));
      return;
    }
    if (ultimos4.length != 4 || int.tryParse(ultimos4) == null) {
      setState(() => _error = tr(context, 'comprador_secundario.error_ultimos4'));
      return;
    }
    Navigator.pop(context, {
      'marca': _marca,
      'ultimos_4': ultimos4,
      'nombre_titular': _ctrlTitular.text.trim(),
      'mes_vencimiento': _mes,
      'anio_vencimiento': _anio,
      if (_ctrlAlias.text.trim().isNotEmpty) 'alias': _ctrlAlias.text.trim(),
      'predeterminada': _predeterminada,
    });
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final anioActual = DateTime.now().year;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: CraftHubColors.panel(esOscuro),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: CraftHubColors.borde(esOscuro), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              Text(tr(context, 'comprador_secundario.agregar_tarjeta_titulo'),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: colorTexto)),
              const SizedBox(height: 4),
              Text(tr(context, 'comprador_secundario.agregar_tarjeta_aviso'),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(esOscuro))),
              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                initialValue: _marca,
                decoration: InputDecoration(labelText: tr(context, 'comprador_secundario.marca_label'), border: const OutlineInputBorder()),
                items: _marcasTarjeta.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _marca = v ?? _marca),
              ),
              const SizedBox(height: 14),
              CampoTexto(
                controlador: _ctrlTitular,
                hint: tr(context, 'comprador_secundario.nombre_titular_hint'),
                icono: Icons.person_outline_rounded,
                esOscuro: esOscuro,
              ),
              const SizedBox(height: 14),
              CampoTexto(
                controlador: _ctrlUltimos4,
                hint: tr(context, 'comprador_secundario.ultimos4_hint'),
                icono: Icons.pin_outlined,
                esOscuro: esOscuro,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _mes,
                      decoration: InputDecoration(labelText: tr(context, 'comprador_secundario.mes_label'), border: const OutlineInputBorder()),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))))
                          .toList(),
                      onChanged: (v) => setState(() => _mes = v ?? _mes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _anio,
                      decoration: InputDecoration(labelText: tr(context, 'comprador_secundario.anio_label'), border: const OutlineInputBorder()),
                      items: List.generate(15, (i) => anioActual + i)
                          .map((a) => DropdownMenuItem(value: a, child: Text(a.toString())))
                          .toList(),
                      onChanged: (v) => setState(() => _anio = v ?? _anio),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CampoTexto(
                controlador: _ctrlAlias,
                hint: tr(context, 'comprador_secundario.alias_hint'),
                icono: Icons.label_outline_rounded,
                esOscuro: esOscuro,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _predeterminada,
                onChanged: (v) => setState(() => _predeterminada = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(tr(context, 'comprador_secundario.usar_predeterminada_checkbox'), style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: colorTexto)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CraftHubColors.vinoTinto,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tr(context, 'comprador_secundario.continuar'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
