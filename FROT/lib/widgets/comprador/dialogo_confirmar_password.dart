// lib/widgets/comprador/dialogo_confirmar_password.dart
// Diálogo de reautenticación: pide la contraseña de la cuenta antes de una
// acción sensible sobre tarjetas guardadas (agregar, eliminar, marcar
// predeterminada). 🔌 POST /api/auth/verificar-password
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../campo_texto.dart';

/// Muestra el diálogo y devuelve la contraseña ya verificada como correcta
/// (para que el llamador la reenvíe al endpoint que la necesite), o `null`
/// si el usuario canceló.
Future<String?> mostrarDialogoConfirmarPassword(
  BuildContext context, {
  required String email,
  String titulo = 'Confirma tu identidad',
  String mensaje = 'Ingresa tu contraseña para continuar.',
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DialogoConfirmarPassword(email: email, titulo: titulo, mensaje: mensaje),
  );
}

class _DialogoConfirmarPassword extends StatefulWidget {
  final String email;
  final String titulo;
  final String mensaje;
  const _DialogoConfirmarPassword({required this.email, required this.titulo, required this.mensaje});

  @override
  State<_DialogoConfirmarPassword> createState() => _DialogoConfirmarPasswordState();
}

class _DialogoConfirmarPasswordState extends State<_DialogoConfirmarPassword> {
  final _ctrlPassword = TextEditingController();
  bool _verPassword = false;
  bool _verificando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlPassword.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_ctrlPassword.text.isEmpty || _verificando) return;
    setState(() {
      _verificando = true;
      _error = null;
    });
    try {
      await ApiService.verificarPassword(widget.email, _ctrlPassword.text);
      if (!mounted) return;
      Navigator.of(context).pop(_ctrlPassword.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = CraftHubColors.textoPrincipal(oscuro);
    final colorSec = CraftHubColors.textoSecundario(oscuro);
    final colorBorde = CraftHubColors.borde(oscuro);

    return Dialog(
      backgroundColor: CraftHubColors.panel(oscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: CraftHubColors.vinoTinto, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.titulo,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: colorTexto)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.mensaje,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: colorSec)),
              const SizedBox(height: 18),
              CampoTexto(
                controlador: _ctrlPassword,
                hint: 'Contraseña',
                icono: Icons.key_outlined,
                esOscuro: oscuro,
                esPassword: true,
                verPassword: _verPassword,
                alAlternarVisibilidad: () => setState(() => _verPassword = !_verPassword),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error)),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _verificando ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorSec,
                        side: BorderSide(color: colorBorde),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontFamily: 'Poppins')),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _verificando ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CraftHubColors.vinoTinto,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _verificando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
