import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';

/// Formulario modal para publicar un nuevo video tutorial.
/// Se activa al presionar el botón "+" circular en la TopBar.
class SubirVideoForm extends StatefulWidget {
  const SubirVideoForm({super.key});

  @override
  State<SubirVideoForm> createState() => _SubirVideoFormState();
}

class _SubirVideoFormState extends State<SubirVideoForm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _escalaAnim;

  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  String? _categoriaSeleccionada;
  String? _archivoVideoNombre;
  String? _archivoPosterNombre;
  bool _subiendo = false;

  static const _categorias = [
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
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _escalaAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarVideo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() => _archivoVideoNombre = resultado.files.first.name);
    }
  }

  Future<void> _seleccionarPoster() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() => _archivoPosterNombre = resultado.files.first.name);
    }
  }

  Future<void> _publicarVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_archivoVideoNombre == null) {
      _mostrarError('Por favor selecciona el archivo de video.');
      return;
    }
    setState(() => _subiendo = true);
    // TODO: conectar con FastAPI POST /api/tutoriales/subir
    await Future.delayed(const Duration(seconds: 2)); // simulación
    setState(() => _subiendo = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        backgroundColor: const Color(0xFF821515),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF1A1A1A);
    final colorSubtexto = esOscuro ? Colors.white54 : const Color(0xFF7A7A7A);
    final colorBorde = esOscuro
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE5E0D8);

    return ScaleTransition(
      scale: _escalaAnim,
      child: Dialog(
        backgroundColor: colorFondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Cabecera ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF821515),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedVideo01,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Subir tutorial',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // ── Cuerpo scrollable ─────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        _etiqueta('Título del tutorial *', colorTexto),
                        const SizedBox(height: 6),
                        _campoTexto(
                          controlador: _tituloCtrl,
                          hint: 'Ej: Técnica de Tembleques en Mostacilla',
                          esOscuro: esOscuro,
                          colorBorde: colorBorde,
                          validar: (v) => (v == null || v.trim().isEmpty)
                              ? 'El título es obligatorio'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Descripción
                        _etiqueta('Descripción', colorTexto),
                        const SizedBox(height: 6),
                        _campoTexto(
                          controlador: _descripcionCtrl,
                          hint:
                              'Describe brevemente el contenido del tutorial...',
                          esOscuro: esOscuro,
                          colorBorde: colorBorde,
                          maxLineas: 3,
                        ),

                        const SizedBox(height: 16),

                        // Categoría
                        _etiqueta('Categoría *', colorTexto),
                        const SizedBox(height: 6),
                        _dropdownCategorias(
                          esOscuro,
                          colorFondo,
                          colorBorde,
                          colorTexto,
                        ),

                        const SizedBox(height: 20),

                        // Zona de archivo de video
                        _etiqueta('Archivo de video *', colorTexto),
                        const SizedBox(height: 6),
                        _zonaArchivo(
                          icono: Icons.videocam_rounded,
                          texto:
                              _archivoVideoNombre ??
                              'Seleccionar video (.mp4, .mov, .avi)',
                          seleccionado: _archivoVideoNombre != null,
                          alPresionar: _seleccionarVideo,
                          esOscuro: esOscuro,
                          colorBorde: colorBorde,
                          colorSubtexto: colorSubtexto,
                        ),

                        const SizedBox(height: 14),

                        // Zona de imagen de portada
                        _etiqueta('Imagen de portada (opcional)', colorTexto),
                        const SizedBox(height: 6),
                        _zonaArchivo(
                          icono: Icons.image_rounded,
                          texto:
                              _archivoPosterNombre ??
                              'Seleccionar portada (.jpg, .png)',
                          seleccionado: _archivoPosterNombre != null,
                          alPresionar: _seleccionarPoster,
                          esOscuro: esOscuro,
                          colorBorde: colorBorde,
                          colorSubtexto: colorSubtexto,
                        ),

                        const SizedBox(height: 24),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorBorde),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colorSubtexto,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _subiendo ? null : _publicarVideo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF821515),
                                  disabledBackgroundColor: const Color(
                                    0xFF821515,
                                  ).withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _subiendo
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.upload_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Publicar tutorial',
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers de construcción de UI ──────────────────────────────────────

  Widget _etiqueta(String texto, Color color) => Text(
    texto,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );

  Widget _campoTexto({
    required TextEditingController controlador,
    required String hint,
    required bool esOscuro,
    required Color colorBorde,
    int maxLineas = 1,
    String? Function(String?)? validar,
  }) {
    return TextFormField(
      controller: controlador,
      maxLines: maxLineas,
      validator: validar,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: esOscuro ? Colors.white : const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: esOscuro ? Colors.white38 : const Color(0xFFB0A898),
        ),
        filled: true,
        fillColor: esOscuro ? const Color(0xFF2A2A2A) : const Color(0xFFFAF8F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
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
          borderSide: const BorderSide(color: Color(0xFF821515), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownCategorias(
    bool esOscuro,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: _categoriaSeleccionada,
      validator: (v) => v == null ? 'Selecciona una categoría' : null,
      onChanged: (v) => setState(() => _categoriaSeleccionada = v),
      dropdownColor: esOscuro ? const Color(0xFF2A2A2A) : Colors.white,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorTexto),
      decoration: InputDecoration(
        hintText: 'Seleccionar categoría',
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: esOscuro ? Colors.white38 : const Color(0xFFB0A898),
        ),
        filled: true,
        fillColor: esOscuro ? const Color(0xFF2A2A2A) : const Color(0xFFFAF8F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
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
          borderSide: const BorderSide(color: Color(0xFF821515), width: 1.5),
        ),
      ),
      items: _categorias
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(
                c,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _zonaArchivo({
    required IconData icono,
    required String texto,
    required bool seleccionado,
    required VoidCallback alPresionar,
    required bool esOscuro,
    required Color colorBorde,
    required Color colorSubtexto,
  }) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFF821515).withValues(alpha: 0.06)
              : (esOscuro ? const Color(0xFF2A2A2A) : const Color(0xFFFAF8F5)),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF821515).withValues(alpha: 0.5)
                : colorBorde,
            width: seleccionado ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: seleccionado ? const Color(0xFF821515) : colorSubtexto,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: seleccionado ? const Color(0xFF821515) : colorSubtexto,
                  fontWeight: seleccionado
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (seleccionado)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF821515),
                size: 18,
              )
            else
              Icon(Icons.add_rounded, color: colorSubtexto, size: 18),
          ],
        ),
      ),
    );
  }
}
