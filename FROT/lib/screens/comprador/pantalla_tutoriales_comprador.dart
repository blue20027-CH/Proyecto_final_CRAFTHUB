import 'package:flutter/material.dart';
import '../vendedor/pantalla_tutoriales.dart';

class PantallaTutorialesComprador extends StatelessWidget {
  final String userId;

  const PantallaTutorialesComprador({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return PantallaTutoriales(
      userId: userId,
      esVendedor: false,
    );
  }
}