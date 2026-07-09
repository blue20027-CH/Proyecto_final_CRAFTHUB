import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Avatar de un contacto de chat con iniciales de respaldo: si
/// [avatarUrl] no carga (o está vacío), muestra las iniciales de
/// [nombre] en vez de un círculo vacío.
class AvatarContacto extends StatelessWidget {
  final String nombre;
  final String avatarUrl;
  final double radio;

  const AvatarContacto({
    super.key,
    required this.nombre,
    required this.avatarUrl,
    this.radio = 22,
  });

  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? '?' : texto;
  }

  @override
  Widget build(BuildContext context) {
    final tamano = radio * 2;
    Widget imagen;
    if (avatarUrl.isEmpty) {
      imagen = _respaldo(tamano);
    } else if (avatarUrl.startsWith('assets/')) {
      imagen = Image.asset(avatarUrl, width: tamano, height: tamano, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _respaldo(tamano));
    } else {
      imagen = Image.network(avatarUrl, width: tamano, height: tamano, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _respaldo(tamano));
    }
    return ClipOval(child: imagen);
  }

  Widget _respaldo(double tamano) => Container(
        width: tamano,
        height: tamano,
        color: CraftHubColors.vinoTintoSuave,
        alignment: Alignment.center,
        child: Text(
          _iniciales,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: radio * 0.62,
            fontWeight: FontWeight.w700,
            color: CraftHubColors.vinoTinto,
          ),
        ),
      );
}
