import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';

/// Diálogo modal para subir un nuevo tutorial de video.
/// 🔌 POST /api/tutoriales/subir
///   Body (multipart/form-data):
///     - titulo: String
///     - descripcion: String
///     - categoria: String
///     - video: File (mp4/mov/avi)
///     - miniatura: File (jpg/png) [opcional]
///   Response: { "id": String, "mensaje": String }
class DialogoSubirVideo extends StatefulWidget {
  const DialogoSubirVideo({super.key});

  @override
  State<DialogoSubirVideo> createState() => _DialogoSubirVideoState();
}

class _DialogoSubirVideoState extends State<DialogoSubirVideo> {
  final _formKey = GlobalKey<FormState>();
  final _controladorTitulo = TextEditingController();
  final _controladorDescripcion = TextEditingController();

  String? _categoriaSeleccionada;
  String? _rutaVideoSeleccionado;
  String? _nombreArchivoVideo;
  String? _rutaMiniaturaSeleccionada;
  String? _nombreArchivoMiniatura;
  bool _subiendoArchivo = false;

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
    super.dispose();
  }

  Future<void> _seleccionarVideo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() {
        _rutaVideoSeleccionado = resultado.files.single.path;
        _nombreArchivoVideo = resultado.files.single.name;
      });
    }
  }

  Future<void> _seleccionarMiniatura() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() {
        _rutaMiniaturaSeleccionada = resultado.files.single.path;
        _nombreArchivoMiniatura = resultado.files.single.name;
      });
    }
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rutaVideoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un archivo de video.'),
        ),
      );
      return;
    }
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría.')),
      );
      return;
    }

    setState(() => _subiendoArchivo = true);

    if (_rutaMiniaturaSeleccionada != null) {
      // La miniatura está seleccionada y se usará en la integración real del backend.
    }

    // 🔌 INTEGRACIÓN API – reemplazar el bloque de abajo con la llamada HTTP real:
    // ─────────────────────────────────────────────────────────────────────────
    // final request = http.MultipartRequest(
    //   'POST',
    //   Uri.parse('https://TU_BACKEND/api/tutoriales/subir'),
    // );
    // request.headers['Authorization'] = 'Bearer $tokenDelUsuario';
    // request.fields['titulo'] = _controladorTitulo.text.trim();
    // request.fields['descripcion'] = _controladorDescripcion.text.trim();
    // request.fields['categoria'] = _categoriaSeleccionada!;
    // request.files.add(await http.MultipartFile.fromPath('video', _rutaVideoSeleccionado!));
    // if (_rutaMiniaturaSeleccionada != null) {
    //   request.files.add(await http.MultipartFile.fromPath('miniatura', _rutaMiniaturaSeleccionada!));
    // }
    // final streamedResponse = await request.send();
    // final response = await http.Response.fromStream(streamedResponse);
    // if (response.statusCode == 201) {
    //   final data = jsonDecode(response.body);
    //   // data['id'] → ID del tutorial creado en el backend
    // }
    // ─────────────────────────────────────────────────────────────────────────

    // Simulación de subida (eliminar cuando conectes el backend)
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _subiendoArchivo = false);

    if (mounted) Navigator.of(context).pop();
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
                          'Subir mi video',
                          style: TextStyle(
                            color: colorTexto,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Comparte tu conocimiento con la comunidad',
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

                // ── Selector de archivo de video ─────────────────────────────
                _LabelCampo(
                  texto: 'Archivo de video *',
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _seleccionarVideo,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _rutaVideoSeleccionado != null
                          ? CraftHubColors.vinoTintoSuave.withOpacity(
                              esOscuro ? 0.15 : 0.5,
                            )
                          : CraftHubColors.fondo(esOscuro),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _rutaVideoSeleccionado != null
                            ? CraftHubColors.vinoTinto
                            : colorBorde,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _rutaVideoSeleccionado != null
                              ? Icons.check_circle_rounded
                              : Icons.video_file_outlined,
                          color: _rutaVideoSeleccionado != null
                              ? CraftHubColors.vinoTinto
                              : colorSec,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _rutaVideoSeleccionado != null
                              ? _nombreArchivoVideo!
                              : 'Haz clic para seleccionar un video',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _rutaVideoSeleccionado != null
                                ? CraftHubColors.vinoTinto
                                : colorSec,
                            fontSize: 13,
                            fontWeight: _rutaVideoSeleccionado != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (_rutaVideoSeleccionado == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Formatos: MP4, MOV, AVI (máx. 500 MB)',
                              style: TextStyle(
                                color: colorSec,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Título ───────────────────────────────────────────────────
                _LabelCampo(
                  texto: 'Título del tutorial *',
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 8),
                _CampoTexto(
                  controlador: _controladorTitulo,
                  placeholder: 'Ej. Técnica de bordado Mola paso a paso',
                  esOscuro: esOscuro,
                  validador: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    if (v.trim().length < 5) {
                      return 'El título debe tener al menos 5 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Descripción ──────────────────────────────────────────────
                _LabelCampo(texto: 'Descripción', colorTexto: colorTexto),
                const SizedBox(height: 8),
                _CampoTexto(
                  controlador: _controladorDescripcion,
                  placeholder:
                      'Describe brevemente qué aprenderán los espectadores...',
                  esOscuro: esOscuro,
                  maxLineas: 3,
                ),
                const SizedBox(height: 20),

                // ── Categoría ────────────────────────────────────────────────
                _LabelCampo(texto: 'Categoría *', colorTexto: colorTexto),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    hintText: 'Selecciona una categoría',
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
                  validator: (v) =>
                      v == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: 20),

                // ── Miniatura (opcional) ──────────────────────────────────────
                _LabelCampo(
                  texto: 'Miniatura personalizada (opcional)',
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CraftHubColors.fondo(esOscuro),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorBorde),
                        ),
                        child: Text(
                          _nombreArchivoMiniatura ??
                              'Ningún archivo seleccionado',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _nombreArchivoMiniatura != null
                                ? colorTexto
                                : colorSec,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _seleccionarMiniatura,
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: const Text(
                        'Explorar',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CraftHubColors.vinoTinto,
                        side: const BorderSide(color: CraftHubColors.vinoTinto),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Botones de acción ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _subiendoArchivo
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
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _subiendoArchivo ? null : _enviarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CraftHubColors.vinoTinto,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _subiendoArchivo
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Subir tutorial',
                                style: TextStyle(
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
