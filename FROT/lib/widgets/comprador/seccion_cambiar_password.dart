// lib/widgets/comprador/seccion_cambiar_password.dart
// Formulario de cambio de contraseña, mostrado como hoja modal desde la
// fila "Cambiar contraseña" de la sección Seguridad y privacidad. El propio
// formulario exige la contraseña actual, que el backend reverifica contra
// Supabase Auth antes de aplicar la nueva — no hace falta un diálogo de
// reautenticación aparte (a diferencia de tarjetas, donde la sesión ya está
// iniciada y la contraseña se pide solo para esa acción puntual).
// 🔌 PATCH /api/auth/cambiar-password (BACK/CraftHub/auth_router.py)
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../campo_texto.dart';

Future<void> mostrarModalCambiarPassword(
  BuildContext context, {
  required String email,
  required bool esOscuro,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HojaCambiarPassword(email: email, esOscuro: esOscuro),
  );
}

class _HojaCambiarPassword extends StatefulWidget {
  final String email;
  final bool esOscuro;
  const _HojaCambiarPassword({required this.email, required this.esOscuro});

  @override
  State<_HojaCambiarPassword> createState() => _HojaCambiarPasswordState();
}

class _HojaCambiarPasswordState extends State<_HojaCambiarPassword> {
  final _ctrlActual = TextEditingController();
  final _ctrlNueva = TextEditingController();
  final _ctrlConfirmar = TextEditingController();
  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirmar = false;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlActual.dispose();
    _ctrlNueva.dispose();
    _ctrlConfirmar.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    final actual = _ctrlActual.text;
    final nueva = _ctrlNueva.text;
    final confirmar = _ctrlConfirmar.text;

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      setState(() => _error = 'Completa los tres campos.');
      return;
    }
    if (nueva.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (nueva != confirmar) {
      setState(() => _error = 'La nueva contraseña y su confirmación no coinciden.');
      return;
    }
    if (nueva == actual) {
      setState(() => _error = 'La nueva contraseña debe ser diferente a la actual.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ApiService.cambiarPassword(widget.email, actual, nueva);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente.')),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);

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
              Text('Cambiar contraseña',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: colorTexto)),
              const SizedBox(height: 4),
              Text('Actualiza tu contraseña de forma segura.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(esOscuro))),
              const SizedBox(height: 18),

              CampoTexto(
                controlador: _ctrlActual,
                hint: 'Contraseña actual',
                icono: Icons.key_outlined,
                esOscuro: esOscuro,
                esPassword: true,
                verPassword: _verActual,
                alAlternarVisibilidad: () => setState(() => _verActual = !_verActual),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                controlador: _ctrlNueva,
                hint: 'Nueva contraseña',
                icono: Icons.lock_outline_rounded,
                esOscuro: esOscuro,
                esPassword: true,
                verPassword: _verNueva,
                alAlternarVisibilidad: () => setState(() => _verNueva = !_verNueva),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                controlador: _ctrlConfirmar,
                hint: 'Confirmar nueva contraseña',
                icono: Icons.lock_outline_rounded,
                esOscuro: esOscuro,
                esPassword: true,
                verPassword: _verConfirmar,
                alAlternarVisibilidad: () => setState(() => _verConfirmar = !_verConfirmar),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _cambiar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CraftHubColors.vinoTinto,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _enviando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Actualizar contraseña', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
