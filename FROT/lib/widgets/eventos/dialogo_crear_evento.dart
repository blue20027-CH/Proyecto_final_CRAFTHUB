// lib/widgets/eventos/dialogo_crear_evento.dart
//
// Formulario para que el vendedor/organizador publique un nuevo evento
// artesanal en el calendario. 🔌 POST /api/eventos

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/evento_modelo.dart';
import '../../services/eventos_api_service.dart';

Future<EventoArtesanal?> mostrarDialogoCrearEvento(
  BuildContext context, {
  required String nombreOrganizador,
  required String telefonoOrganizador,
}) {
  return showDialog<EventoArtesanal>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => DialogoCrearEvento(
      nombreOrganizador: nombreOrganizador,
      telefonoOrganizador: telefonoOrganizador,
    ),
  );
}

class DialogoCrearEvento extends StatefulWidget {
  final String nombreOrganizador;
  final String telefonoOrganizador;

  const DialogoCrearEvento({
    super.key,
    required this.nombreOrganizador,
    required this.telefonoOrganizador,
  });

  @override
  State<DialogoCrearEvento> createState() => _DialogoCrearEventoState();
}

class _DialogoCrearEventoState extends State<DialogoCrearEvento> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _cuposCtrl = TextEditingController(text: '20');
  late final TextEditingController _telefonoCtrl =
      TextEditingController(text: widget.telefonoOrganizador);

  String _categoria = categoriasEvento[1];
  String _provincia = provinciasEvento.first;
  DateTime _fechaInicio = DateTime.now().add(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 8));
  bool _esGratuito = true;
  bool _publicando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _cuposCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (seleccion == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = seleccion;
        if (_fechaFin.isBefore(_fechaInicio)) _fechaFin = _fechaInicio;
      } else {
        _fechaFin = seleccion;
      }
    });
  }

  Future<void> _publicarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _publicando = true);

    final evento = await EventosApiService.crearEvento({
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'categoria': _categoria,
      'imagen_url': '',
      'fecha_inicio': _fechaInicio.toIso8601String(),
      'fecha_fin': _fechaFin.toIso8601String(),
      'ubicacion': _ubicacionCtrl.text.trim(),
      'provincia': _provincia,
      'es_gratuito': _esGratuito,
      'cupos_vendedor_total': int.tryParse(_cuposCtrl.text) ?? 0,
      'cupos_vendedor_disponibles': int.tryParse(_cuposCtrl.text) ?? 0,
      'organizador': {
        'nombre': widget.nombreOrganizador,
        'tipo': 'Vendedor organizador',
        'telefono': _telefonoCtrl.text.trim(),
        'whatsapp': _telefonoCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      },
    });

    if (!mounted) return;
    setState(() => _publicando = false);
    Navigator.of(context).pop(evento);
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = CraftHubColors.textoPrincipal(oscuro);
    final colorSec = CraftHubColors.textoSecundario(oscuro);
    final colorBorde = CraftHubColors.borde(oscuro);

    InputDecoration decoracion(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorSec, fontSize: 13, fontFamily: 'Poppins'),
          filled: true,
          fillColor: CraftHubColors.fondo(oscuro),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorBorde)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorBorde)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.5),
          ),
        );

    TextStyle etiqueta() => TextStyle(
        color: colorTexto, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins');

    return Dialog(
      backgroundColor: CraftHubColors.panel(oscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: CraftHubColors.vinoTinto,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(context, 'compartido.publicar_evento'),
                              style: TextStyle(
                                  color: colorTexto,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins')),
                          Text(tr(context, 'compartido.publicar_evento_subtitulo'),
                              style: TextStyle(color: colorSec, fontSize: 12, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorSec),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('${tr(context, 'compartido.evento_titulo_label')} *', style: etiqueta()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tituloCtrl,
                  style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                  decoration: decoracion(tr(context, 'compartido.evento_titulo_hint')),
                  validator: (v) =>
                      (v == null || v.trim().length < 4) ? tr(context, 'compartido.evento_titulo_error') : null,
                ),
                const SizedBox(height: 16),

                Text(tr(context, 'compartido.descripcion_label'), style: etiqueta()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                  decoration: decoracion(tr(context, 'compartido.evento_descripcion_hint')),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(context, 'compartido.categoria_label')} *', style: etiqueta()),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _categoria,
                          decoration: decoracion(tr(context, 'compartido.categoria_label')),
                          dropdownColor: CraftHubColors.panel(oscuro),
                          style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                          items: categoriasEvento
                              .where((c) => c != 'Todos')
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _categoria = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(context, 'compartido.provincia_comarca_label')} *', style: etiqueta()),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _provincia,
                          decoration: decoracion(tr(context, 'compartido.provincia_comarca_label')),
                          dropdownColor: CraftHubColors.panel(oscuro),
                          isExpanded: true,
                          style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                          items: provinciasEvento
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) => setState(() => _provincia = v!),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                Text('${tr(context, 'compartido.lugar_direccion_label')} *', style: etiqueta()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ubicacionCtrl,
                  style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                  decoration: decoracion(tr(context, 'compartido.lugar_hint')),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? tr(context, 'compartido.lugar_error') : null,
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(context, 'compartido.fecha_inicio_label')} *', style: etiqueta()),
                        const SizedBox(height: 8),
                        _SelectorFecha(
                          fecha: _fechaInicio,
                          onTap: () => _elegirFecha(esInicio: true),
                          colorTexto: colorTexto,
                          colorBorde: colorBorde,
                          oscuro: oscuro,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(context, 'compartido.fecha_fin_label')} *', style: etiqueta()),
                        const SizedBox(height: 8),
                        _SelectorFecha(
                          fecha: _fechaFin,
                          onTap: () => _elegirFecha(esInicio: false),
                          colorTexto: colorTexto,
                          colorBorde: colorBorde,
                          oscuro: oscuro,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(context, 'compartido.cupos_vendedores_label'), style: etiqueta()),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cuposCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                          decoration: decoracion('Ej. 20'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(context, 'compartido.telefono_contacto_label')} *', style: etiqueta()),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _telefonoCtrl,
                          style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
                          decoration: decoracion('+507 6000-0000'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? tr(context, 'compartido.telefono_error') : null,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Switch(
                      value: _esGratuito,
                      activeThumbColor: CraftHubColors.vinoTinto,
                      onChanged: (v) => setState(() => _esGratuito = v),
                    ),
                    const SizedBox(width: 8),
                    Text(tr(context, 'compartido.entrada_gratuita'), style: etiqueta()),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _publicando ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorSec,
                          side: BorderSide(color: colorBorde),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(tr(context, 'compartido.cancelar'), style: const TextStyle(fontFamily: 'Poppins')),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _publicando ? null : _publicarEvento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CraftHubColors.vinoTinto,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _publicando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(tr(context, 'compartido.publicar_evento'),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;
  final Color colorTexto;
  final Color colorBorde;
  final bool oscuro;

  const _SelectorFecha({
    required this.fecha,
    required this.onTap,
    required this.colorTexto,
    required this.colorBorde,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CraftHubColors.fondo(oscuro),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorBorde),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: CraftHubColors.vinoTinto),
            const SizedBox(width: 10),
            Text(
              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
              style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}
