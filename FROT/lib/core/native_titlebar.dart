// Sincroniza la barra de título nativa de Windows (color de fondo, texto y
// botones) con el tema claro/oscuro elegido dentro de la app, en vez de
// dejar que siga únicamente el tema del sistema operativo.
// Ver: windows/runner/flutter_window.cpp (canal "crafthub/titlebar").
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeTitleBar {
  NativeTitleBar._();

  static const MethodChannel _canal = MethodChannel('crafthub/titlebar');
  static bool? _ultimoOscuro;

  static Future<void> sincronizar(bool esOscuro) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (_ultimoOscuro == esOscuro) return;
    _ultimoOscuro = esOscuro;
    try {
      await _canal.invokeMethod('setDarkMode', esOscuro);
    } on PlatformException {
      // Silencioso: si el canal falla, la barra conserva el color que
      // Windows aplicó por defecto según el tema del sistema.
    }
  }
}
