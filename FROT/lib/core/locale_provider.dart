import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guarda el idioma elegido por el usuario (es/en) y lo persiste entre
// sesiones, igual que GestorTema hace con el modo oscuro.
class LocaleProvider extends ChangeNotifier {
  static const _clavePrefs = 'crafthub_idioma';

  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  bool get esIngles => _locale.languageCode == 'en';

  LocaleProvider() {
    _cargarIdiomaGuardado();
  }

  Future<void> _cargarIdiomaGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clavePrefs);
    if (guardado == 'en' || guardado == 'es') {
      _locale = Locale(guardado!);
      notifyListeners();
    }
  }

  Future<void> alternarIdioma() async {
    await establecerIdioma(esIngles ? 'es' : 'en');
  }

  // Selección explícita (p. ej. desde un menú con "Español"/"English" en vez
  // de un simple toggle de dos estados).
  Future<void> establecerIdioma(String codigo) async {
    if (codigo != 'es' && codigo != 'en') return;
    _locale = Locale(codigo);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePrefs, _locale.languageCode);
  }
}
