import 'package:flutter/material.dart';

class CraftHubColors {

  // ─── PRIMARIO / ACENTO ─────────────────────────────────────────────────────
  static const Color vinoTinto       = Color(0xFF821515);
  static const Color vinoTintoOscuro = Color(0xFF5E0F0F);
  static const Color vinoTintoClaro  = Color(0xFFAB2020);
  static const Color vinoTintoSuave  = Color(0xFFF5E6E6); // fondo hover sutil

  // ─── TEMA CLARO ────────────────────────────────────────────────────────────
  static const Color fondoClaro      = Color(0xFFF9F6F0); // crema ultrasuave
  static const Color panelClaro      = Color(0xFFFFFFFF); // blanco sólido
  static const Color textoClaro      = Color(0xFF1A1A1A); // casi negro
  static const Color textoSecClaro   = Color(0xFF6B6B6B); // gris medio
  static const Color bordeClaro      = Color(0xFFE0D8CE); // borde cálido

  // ─── TEMA OSCURO ───────────────────────────────────────────────────────────
  static const Color fondoOscuro     = Color(0xFF121212); // gris carbón
  static const Color panelOscuro     = Color(0xFF1E1E1E); // gris mate
  static const Color panelOscuro2    = Color(0xFF252525); // capa secundaria
  static const Color textoOscuro     = Color(0xFFF0EAE0); // blanco cálido
  static const Color textoSecOscuro  = Color(0xFFAAAAAA); // gris claro
  static const Color bordeOscuro     = Color(0xFF2E2E2E); // borde oscuro

  // ─── UTILIDADES GENERALES ──────────────────────────────────────────────────
  static const Color exito           = Color(0xFF2E7D32); // verde éxito
  static const Color advertencia     = Color(0xFFF57F17); // naranja alerta
  static const Color error           = Color(0xFFC62828); // rojo error
  static const Color info            = Color(0xFF1565C0); // azul info

  static const Color transparente    = Colors.transparent;
  static const Color negro           = Color(0xFF000000);
  static const Color blanco          = Color(0xFFFFFFFF);

  // ─── OVERLAY / SOMBRAS ─────────────────────────────────────────────────────
  static Color sombra(double opacidad) =>
      Colors.black.withOpacity(opacidad);

  static Color veloClaro(double opacidad) =>
      const Color(0xFFF5EDE3).withOpacity(opacidad);

  static Color veloOscuro(double opacidad) =>
      const Color(0xFF0D0D0D).withOpacity(opacidad);

  /// Devuelve el color de texto principal según el tema activo
  static Color textoPrincipal(bool esOscuro) =>
      esOscuro ? textoOscuro : textoClaro;

  /// Devuelve el color de texto secundario según el tema activo
  static Color textoSecundario(bool esOscuro) =>
      esOscuro ? textoSecOscuro : textoSecClaro;

  /// Devuelve el color de fondo del panel según el tema activo
  static Color panel(bool esOscuro) =>
      esOscuro ? panelOscuro : panelClaro;

  /// Devuelve el color de fondo general según el tema activo
  static Color fondo(bool esOscuro) =>
      esOscuro ? fondoOscuro : fondoClaro;

  /// Devuelve el color de borde según el tema activo
  static Color borde(bool esOscuro) =>
      esOscuro ? bordeOscuro : bordeClaro;
}

class CraftHubTheme {
  static ThemeData temaClaro() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: CraftHubColors.fondoClaro,
      primaryColor: CraftHubColors.vinoTinto,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: CraftHubColors.vinoTinto,
        onPrimary: Colors.white,
        surface: CraftHubColors.panelClaro,
        onSurface: CraftHubColors.textoClaro,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CraftHubColors.vinoTinto,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData temaOscuro() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CraftHubColors.fondoOscuro,
      primaryColor: CraftHubColors.vinoTinto,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: CraftHubColors.vinoTinto,
        onPrimary: Colors.white,
        surface: CraftHubColors.panelOscuro,
        onSurface: CraftHubColors.textoOscuro,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CraftHubColors.vinoTinto,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Alias para compatibilidad con widgets generados
typedef AppColors = CraftHubColors;