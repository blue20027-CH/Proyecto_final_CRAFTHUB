import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../services/chat_api_service.dart';

/// Barra de entrada. Soporta: texto, emoji rapido, foto, compartir publicacion.
/// NO incluye audio ni video.
class BarraInputChat extends StatefulWidget {
  final ValueChanged<String> alEnviarTexto;
  final ValueChanged<String> alEnviarImagen;
  final VoidCallback alCompartirPublicacion;

  const BarraInputChat({
    super.key,
    required this.alEnviarTexto,
    required this.alEnviarImagen,
    required this.alCompartirPublicacion,
  });

  @override
  State<BarraInputChat> createState() => _BarraInputChatState();
}

class _BarraInputChatState extends State<BarraInputChat> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _foco = FocusNode();
  bool _tieneTexto = false;
  bool _mostrarEmojis = false;
  bool _subiendoImagen = false;

  static const _emojis = [
    '😊',
    '😍',
    '👋',
    '🙏',
    '👍',
    '❤️',
    '🎨',
    '✨',
    '🛍️',
    '💬',
    '🚚',
    '😮',
    '🤩',
    '🙌',
    '💪',
    '🌟',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final tiene = _ctrl.text.trim().isNotEmpty;
      if (tiene != _tieneTexto) setState(() => _tieneTexto = tiene);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    widget.alEnviarTexto(texto);
    _ctrl.clear();
    setState(() => _tieneTexto = false);
    _foco.requestFocus();
  }

  Future<void> _seleccionarImagen() async {
    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'compartido.error_selector_imagenes')}${e.toString().replaceAll('Exception: ', '')}')),
      );
      return;
    }
    if (res == null || res.files.isEmpty) return;
    final archivo = res.files.first;
    final bytes = archivo.bytes;
    if (bytes == null) return;

    setState(() => _subiendoImagen = true);
    try {
      final url = await ChatApiService.subirImagenChat(bytes, archivo.name);
      widget.alEnviarImagen(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'compartido.error_subir_imagen_chat')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel emojis rapidos
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _mostrarEmojis
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: isDark
                      ? CraftHubColors.panelOscuro2
                      : CraftHubColors.fondoClaro,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _emojis
                        .map(
                          (e) => InkWell(
                            onTap: () {
                              _ctrl.text += e;
                              _ctrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: _ctrl.text.length),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Barra principal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CraftHubColors.panel(isDark),
            border: Border(
              top: BorderSide(color: CraftHubColors.borde(isDark)),
            ),
          ),
          child: Row(
            children: [
              _Btn(
                icono: Icons.emoji_emotions_outlined,
                tooltip: tr(context, 'compartido.emojis_tooltip'),
                isDark: isDark,
                activo: _mostrarEmojis,
                onTap: () => setState(() => _mostrarEmojis = !_mostrarEmojis),
              ),
              const SizedBox(width: 6),
              _subiendoImagen
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CraftHubColors.vinoTinto),
                      ),
                    )
                  : _Btn(
                      icono: Icons.photo_outlined,
                      tooltip: tr(context, 'compartido.enviar_foto'),
                      isDark: isDark,
                      onTap: _seleccionarImagen,
                    ),
              const SizedBox(width: 6),
              _Btn(
                icono: Icons.storefront_outlined,
                tooltip: tr(context, 'compartido.compartir_publicacion'),
                isDark: isDark,
                onTap: widget.alCompartirPublicacion,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Focus(
                  // Enter envía; Shift+Enter inserta un salto de línea. Se
                  // intercepta a nivel de tecla porque el campo es multilínea.
                  onKeyEvent: (node, evento) {
                    if (evento is KeyDownEvent &&
                        evento.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _enviar();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                  controller: _ctrl,
                  focusNode: _foco,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: tr(context, 'compartido.escribe_mensaje_hint'),
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      color: CraftHubColors.textoSecundario(isDark),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? CraftHubColors.panelOscuro2
                        : CraftHubColors.fondoClaro,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _enviar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _tieneTexto
                        ? CraftHubColors.vinoTinto
                        : CraftHubColors.textoSecundario(
                            isDark,
                          ).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _tieneTexto
                        ? Colors.white
                        : CraftHubColors.textoSecundario(isDark),
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final bool isDark;
  final bool activo;
  final VoidCallback onTap;
  const _Btn({
    required this.icono,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icono,
            size: 22,
            color: activo
                ? CraftHubColors.vinoTinto
                : CraftHubColors.textoSecundario(isDark),
          ),
        ),
      ),
    );
  }
}
