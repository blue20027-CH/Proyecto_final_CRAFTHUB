import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/inicio_screen.dart';

/// Gestor global del tema de la aplicación
class GestorTema extends ChangeNotifier {
  bool _modoOscuro = false;

  bool get esModoOscuro => _modoOscuro;

  void alternarTema() {
    _modoOscuro = !_modoOscuro;
    notifyListeners();
  }
}

void main() {
  debugPaintBaselinesEnabled = false;
  runApp(
    ChangeNotifierProvider(
      create: (_) => GestorTema(),
      child: const CraftHubApp(),
    ),
  );
}

class CraftHubApp extends StatelessWidget {
  const CraftHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorTema>();
    return MaterialApp(
      title: 'CraftHub',
      debugShowCheckedModeBanner: false,
      theme: CraftHubTheme.temaClaro(),
      darkTheme: CraftHubTheme.temaOscuro(),
      themeMode: gestor.esModoOscuro ? ThemeMode.dark : ThemeMode.light,
      home: const PantallaInicio(),
    );
  }
}
