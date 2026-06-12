import 'package:flutter/material.dart';

class AppTextStyles {
  static const String _fontPoppins  = 'Poppins';
  static const String _fontPlayfairDisplay  = 'PlayfairDisplay';

  // ─── TÍTULOS (PlayfairDisplay) ────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontPlayfairDisplay,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: Color(0xFF1A1A1A),
  );

  // ─── ENCABEZADOS (Poppins) ────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A1A),
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A1A),
  );

  // ─── CUERPO (Poppins) ─────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B6B6B),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B6B6B),
  );

  // ─── BOTONES / ETIQUETAS ──────────────────────────────────────────────────
  static const TextStyle labelButton = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.5,
  );

  // ─── SUBTEXTOS ────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFFAAAAAA),
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: _fontPoppins,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B6B6B),
    letterSpacing: 4,
  );

  // ─── HELPERS ADAPTATIVOS (para tema claro/oscuro) ─────────────────────────

  /// Título principal adaptado al tema activo
  static TextStyle displayAdaptivo(bool esOscuro) => displayLarge.copyWith(
        color: esOscuro ? const Color(0xFFF0EAE0) : const Color(0xFF1A1A1A),
      );

  /// Encabezado adaptado al tema activo
  static TextStyle headingAdaptivo(bool esOscuro) => headingLarge.copyWith(
        color: esOscuro ? const Color(0xFFF0EAE0) : const Color(0xFF1A1A1A),
      );

  /// Cuerpo adaptado al tema activo
  static TextStyle bodyAdaptivo(bool esOscuro) => bodyMedium.copyWith(
        color: esOscuro ? const Color(0xFFAAAAAA) : const Color(0xFF6B6B6B),
      );

  /// Caption adaptado al tema activo
  static TextStyle captionAdaptivo(bool esOscuro) => caption.copyWith(
        color: esOscuro ? const Color(0xFF888888) : const Color(0xFFAAAAAA),
      );
}