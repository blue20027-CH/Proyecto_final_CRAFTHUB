import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String hint;
  final IconData icono;
  final bool esOscuro;
  final bool esPassword;
  final bool verPassword;
  final VoidCallback? alAlternarVisibilidad;
  final bool readOnly;
  final VoidCallback? onTap;

  const CampoTexto({
    super.key,
    required this.controlador,
    required this.hint,
    required this.icono,
    required this.esOscuro,
    this.esPassword = false,
    this.verPassword = false,
    this.alAlternarVisibilidad,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorFondo = esOscuro
        ? CraftHubColors.panelOscuro
        : CraftHubColors.panelClaro;
    final colorBorde = esOscuro
        ? CraftHubColors.bordeOscuro
        : CraftHubColors.bordeClaro;
    final colorTexto = esOscuro
        ? CraftHubColors.textoOscuro
        : CraftHubColors.textoClaro;
    final colorHint = esOscuro
        ? CraftHubColors.textoSecOscuro
        : CraftHubColors.textoSecClaro;

    return TextField(
  controller: controlador,
  readOnly: readOnly,
  onTap: onTap,
  obscureText: esPassword && !verPassword,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: colorTexto,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: colorHint,
        ),
        filled: true,
        fillColor: colorFondo,
        prefixIcon: Icon(icono, size: 18, color: colorHint),
        suffixIcon: esPassword
            ? IconButton(
                icon: Icon(
                  verPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: colorHint,
                ),
                onPressed: alAlternarVisibilidad,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: colorBorde, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.5),
        ),
      ),
    );
  }
}