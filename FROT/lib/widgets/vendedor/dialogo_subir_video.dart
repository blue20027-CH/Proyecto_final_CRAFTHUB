import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../core/i18n/i18n.dart';

/// Diálogo modal para publicar un nuevo tutorial (enlace de YouTube).
/// 🔌 POST /api/tutoriales — ver ApiService.subirTutorial
class DialogoSubirVideo extends StatefulWidget {
  final String userId;
  const DialogoSubirVideo({super.key, required this.userId});

  @override
  State<DialogoSubirVideo> createState() => _DialogoSubirVideoState();
}

class _DialogoSubirVideoState extends State<DialogoSubirVideo> {
  final _formKey = GlobalKey<FormState>();
  final _controladorTitulo = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _controladorYoutube = TextEditingController();

  String? _categoriaSeleccionada;
  bool _subiendo = false;

  static const List<String> _categorias = [
    'Joyería',
    'Cerámica',
    'Textiles',
    'Madera',
    'Pintura',
    'Accesorios',
    'Decoración',
    'Otras',
  ];

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescripcion.dispose();
    _controladorYoutube.dispose();
    super.dispose();
  }

  String? _validarYoutube(String? v) {
    final url = (v ?? '').trim();
    if (url.isEmpty) return tr(context, 'vendedor_inventario.youtube_requerido');
    if (!url.contains('youtube.com/watch') && !url.contains('youtu.be/')) {
      return tr(context, 'vendedor_inventario.youtube_invalido');
    }
    return null;
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'vendedor_inventario.seleccionar_categoria_snackbar'))),
      );
      return;
    }

    setState(() => _subiendo = true);
    try {
      await ApiService.subirTutorial(
        titulo: _controladorTitulo.text.trim(),
        youtubeUrl: _controladorYoutube.text.trim(),
        creadorId: widget.userId,
        descripcion: _controladorDescripcion.text.trim(),
        categoria: _categoriaSeleccionada!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'vendedor_inventario.no_se_pudo_publicar_tutorial_prefijo')}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.panel(esOscuro);
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    final colorBorde = CraftHubColors.borde(esOscuro);

    return Dialog(
      backgroundColor: colorFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encabezado ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: CraftHubColors.vinoTinto,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.upload_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'vendedor_inventario.subir_mi_video_titulo'),
                          style: TextStyle(
                            color: colorTexto,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          tr(context, 'vendedor_inventario.subir_mi_video_subtitulo'),
                          style: TextStyle(
                            color: colorSec,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorSec),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Enlace de YouTube ─────────────────────────────────────────
                _LabelCampo(
                  texto: tr(context, 'vendedor_inventario.label_enlace_youtube'),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 8),
                _CampoTexto(
                  controlador: _controladorYoutube,
                  placeholder: 'https://www.youtube.com/watch?v=...',
                  esOscuro: esOscuro,
                  validador: _validarYoutube,
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'vendedor_inventario.hint_enlace_ayuda'),
                  style: TextStyle(color: colorSec, fontSize: 11, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 20),

                // ── Título ───────────────────────────────────────────────────
                _LabelCampo(
                  texto: tr(context, 'vendedor_inventario.label_titulo_tutorial'),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 8),
                _CampoTexto(
                  controlador: _controladorTitulo,
                  placeholder: tr(context, 'vendedor_inventario.placeholder_titulo_tutorial'),
                  esOscuro: esOscuro,
                  validador: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return tr(context, 'vendedor_inventario.titulo_requerido');
                    }
                    if (v.trim().length < 5) {
                      return tr(context, 'vendedor_inventario.titulo_min_caracteres');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Descripción ──────────────────────────────────────────────
                _LabelCampo(texto: tr(context, 'vendedor_inventario.seccion_descripcion'), colorTexto: colorTexto),
                const SizedBox(height: 8),
                _CampoTexto(
                  controlador: _controladorDescripcion,
                  placeholder: tr(context, 'vendedor_inventario.placeholder_descripcion_tutorial'),
                  esOscuro: esOscuro,
                  maxLineas: 3,
                ),
                const SizedBox(height: 20),

                // ── Categoría ────────────────────────────────────────────────
                _LabelCampo(texto: tr(context, 'vendedor_inventario.label_categoria_video'), colorTexto: colorTexto),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    hintText: tr(context, 'vendedor_inventario.hint_seleccionar_categoria'),
                    hintStyle: TextStyle(
                      color: colorSec,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: CraftHubColors.fondo(esOscuro),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorBorde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorBorde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: CraftHubColors.vinoTinto,
                        width: 1.5,
                      ),
                    ),
                  ),
                  dropdownColor: colorFondo,
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                  items: _categorias
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                  validator: (v) => v == null
                      ? tr(context, 'vendedor_inventario.hint_seleccionar_categoria')
                      : null,
                ),
                const SizedBox(height: 32),

                // ── Botones de acción ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _subiendo
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorSec,
                          side: BorderSide(color: colorBorde),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          tr(context, 'vendedor_inventario.cancelar'),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _subiendo ? null : _enviarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CraftHubColors.vinoTinto,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _subiendo
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                tr(context, 'vendedor_inventario.subir_tutorial_btn'),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

// ── Helpers de UI internos ────────────────────────────────────────────────────

class _LabelCampo extends StatelessWidget {
  final String texto;
  final Color colorTexto;

  const _LabelCampo({required this.texto, required this.colorTexto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        color: colorTexto,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String placeholder;
  final bool esOscuro;
  final int maxLineas;
  final String? Function(String?)? validador;

  const _CampoTexto({
    required this.controlador,
    required this.placeholder,
    required this.esOscuro,
    this.maxLineas = 1,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      maxLines: maxLineas,
      validator: validador,
      style: TextStyle(
        color: CraftHubColors.textoPrincipal(esOscuro),
        fontSize: 13,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: CraftHubColors.textoSecundario(esOscuro),
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: CraftHubColors.fondo(esOscuro),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: CraftHubColors.borde(esOscuro)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: CraftHubColors.borde(esOscuro)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CraftHubColors.vinoTinto,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CraftHubColors.error),
        ),
      ),
    );
  }
}
