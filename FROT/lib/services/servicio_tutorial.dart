import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda si el usuario ya vio el tutorial de bienvenida con Crafty,
/// separado por rol (un vendedor no debería ver el tour del comprador).
///
/// El estado se guarda por rol, no por usuario: si el mismo usuario cambia
/// de rol en algún momento, se le vuelve a ofrecer el tour que aplica.
class ServicioTutorial {
  static const String _keyComprador = 'tutorial_visto_comprador';
  static const String _keyVendedor = 'tutorial_visto_vendedor';

  static String _keyPara(String rol) =>
      rol.toLowerCase() == 'vendedor' ? _keyVendedor : _keyComprador;

  /// True si ya vio el tour para este rol.
  static Future<bool> yaVioTutorial(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPara(rol)) ?? false;
  }

  /// Se llama al terminar o saltar el tour para que no vuelva a molestar.
  static Future<void> marcarComoVisto(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPara(rol), true);
  }

  /// Botón "Ver tutorial de nuevo" en editar perfil / configuración.
  static Future<void> resetear(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPara(rol));
  }
}
