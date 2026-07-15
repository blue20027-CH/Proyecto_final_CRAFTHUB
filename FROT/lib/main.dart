import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/carrito_provider.dart';
import 'core/favoritos_provider.dart';
import 'core/locale_provider.dart';
import 'core/native_titlebar.dart';
import 'screens/auth/inicio_screen.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GestorTema()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => FavoritosProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const CraftHubApp(),
    ),
  );
}

class CraftHubApp extends StatelessWidget {
  const CraftHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorTema>();
    final idioma = context.watch<LocaleProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NativeTitleBar.sincronizar(gestor.esModoOscuro);
    });
    return MaterialApp(
      title: 'CraftHub',
      debugShowCheckedModeBanner: false,
      theme: CraftHubTheme.temaClaro(),
      darkTheme: CraftHubTheme.temaOscuro(),
      themeMode: gestor.esModoOscuro ? ThemeMode.dark : ThemeMode.light,
      locale: idioma.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PantallaInicio(),
    );
  }
}
