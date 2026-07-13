// lib/screens/navegacion_artesano.dart
// Helper compartido para abrir el perfil completo de un artesano a partir
// de un ArtesanoModelo resumido (usado por el home del comprador y por el
// dropdown de búsqueda global del topbar).

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/artesano_modelo.dart';
import '../services/api_service.dart';
import 'comprador/pantalla_perfil_artesano.dart';

Future<void> abrirPerfilArtesano(BuildContext context, ArtesanoModelo a) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: CraftHubColors.vinoTinto),
    ),
  );

  var productos = <ModeloProductoResumen>[];
  try {
    final detalle = await ApiService.getDetalleArtesano(a.nombre);
    productos = ((detalle['productos'] as List<dynamic>?) ?? [])
        .map(
          (p) => ModeloProductoResumen.fromJson(
            Map<String, dynamic>.from(p as Map),
          ),
        )
        .toList();
  } catch (e) {
    debugPrint('Error cargando productos del artesano: $e');
  }

  if (!context.mounted) return;
  Navigator.pop(context);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PantallaPerfilArtesano(
        artesano: ModeloArtesano(
          nombre: a.nombre,
          specialty: a.especialidad,
          especialidad: a.especialidad,
          ubicacion: a.provincia,
          fotoUrl: a.fotoUrl,
          bannerUrl: a.bannerEfectivo,
          calificacion: a.rating,
          totalResenas: a.totalResenas,
          verificado: a.estaVerificado,
          totalProductos: a.totalVentas,
          anosEnCraftHub: a.anosExperiencia,
          valoracionesPositivas: (a.rating / 5 * 100).round(),
          ventasRealizadas: a.totalVentas,
          descripcion: a.descripcion,
          etiquetas: a.especialidades,
          colecciones: productos.map((p) => p.coleccion).toSet().toList(),
          productos: productos,
        ),
      ),
    ),
  );
}
