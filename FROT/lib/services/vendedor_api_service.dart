import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/modelo_producto_inventario.dart';
import '../widgets/vendedor/tarjeta_producto_ranking.dart';

class DatosDashboardVendedor {
  final String nombreVendedor;
  final double ingresosTotal;
  final double variacionIngresos;
  final List<double> ingresosMensuales;
  final List<String> etiquetasMeses;
  final List<ModeloProductoRanking> topProductos;
  final double promedioEvaluacion;
  final int totalEvaluaciones;
  final Map<int, int> distribucionEvaluaciones;
  final int clientesFelices;
  final int nuevasOpiniones;
  final int pedidosTotales;
  final int pendientesEnviar;
  final int productosActivos;
  final int visitasTienda;

  const DatosDashboardVendedor({
    required this.nombreVendedor,
    required this.ingresosTotal,
    required this.variacionIngresos,
    required this.ingresosMensuales,
    required this.etiquetasMeses,
    required this.topProductos,
    required this.promedioEvaluacion,
    required this.totalEvaluaciones,
    required this.distribucionEvaluaciones,
    required this.clientesFelices,
    required this.nuevasOpiniones,
    required this.pedidosTotales,
    required this.pendientesEnviar,
    required this.productosActivos,
    required this.visitasTienda,
  });

  factory DatosDashboardVendedor.fromJson(Map<String, dynamic> json) {
    final distribucion = json['distribucion_evaluaciones'] as Map? ?? {};
    final top = json['top_productos'] as List? ?? [];

    return DatosDashboardVendedor(
      nombreVendedor: (json['nombre_vendedor'] ?? '').toString(),
      ingresosTotal: double.tryParse((json['ingresos_total'] ?? 0).toString()) ?? 0,
      variacionIngresos: double.tryParse((json['variacion_ingresos'] ?? 0).toString()) ?? 0,
      ingresosMensuales: ((json['ingresos_mensuales'] as List?) ?? [])
          .map((v) => double.tryParse(v.toString()) ?? 0)
          .toList(),
      etiquetasMeses: ((json['etiquetas_meses'] as List?) ?? [])
          .map((v) => v.toString())
          .toList(),
      topProductos: top.map((item) {
        final p = item as Map<String, dynamic>;
        return ModeloProductoRanking(
          posicion: int.tryParse((p['posicion'] ?? 0).toString()) ?? 0,
          nombre: (p['nombre'] ?? '').toString(),
          categoria: (p['categoria'] ?? 'General').toString(),
          imagenUrl: (p['imagen_url'] ?? p['imagen'] ?? p['img'] ?? '').toString(),
          ventas: int.tryParse((p['ventas'] ?? 0).toString()) ?? 0,
          ingresos: double.tryParse((p['ingresos'] ?? 0).toString()) ?? 0,
        );
      }).toList(),
      promedioEvaluacion: double.tryParse((json['promedio_evaluacion'] ?? 0).toString()) ?? 0,
      totalEvaluaciones: int.tryParse((json['total_evaluaciones'] ?? 0).toString()) ?? 0,
      distribucionEvaluaciones: {
        for (final entry in distribucion.entries)
          int.tryParse(entry.key.toString()) ?? 0:
              int.tryParse(entry.value.toString()) ?? 0,
      },
      clientesFelices: int.tryParse((json['clientes_felices'] ?? 0).toString()) ?? 0,
      nuevasOpiniones: int.tryParse((json['nuevas_opiniones'] ?? 0).toString()) ?? 0,
      pedidosTotales: int.tryParse((json['pedidos_totales'] ?? 0).toString()) ?? 0,
      pendientesEnviar: int.tryParse((json['pendientes_enviar'] ?? 0).toString()) ?? 0,
      productosActivos: int.tryParse((json['productos_activos'] ?? 0).toString()) ?? 0,
      visitasTienda: int.tryParse((json['visitas_tienda'] ?? 0).toString()) ?? 0,
    );
  }
}

class InventarioVendedorRespuesta {
  final List<ProductoInventario> productos;
  final Map<String, dynamic> estadisticas;

  const InventarioVendedorRespuesta({
    required this.productos,
    required this.estadisticas,
  });
}

class VendedorApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<DatosDashboardVendedor> cargarDashboard(String nombreVendedor) async {
    final uri = Uri.parse('$baseUrl/api/vendedor/${Uri.encodeComponent(nombreVendedor)}/dashboard');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error cargando dashboard del vendedor');
    }

    return DatosDashboardVendedor.fromJson(jsonDecode(response.body));
  }

  static Future<InventarioVendedorRespuesta> cargarProductos(String nombreVendedor) async {
    final uri = Uri.parse('$baseUrl/api/vendedor/${Uri.encodeComponent(nombreVendedor)}/productos');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error cargando productos del vendedor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final productos = ((data['productos'] as List?) ?? [])
        .map((item) => ProductoInventario.fromJson(item as Map<String, dynamic>))
        .toList();

    return InventarioVendedorRespuesta(
      productos: productos,
      estadisticas: data['estadisticas'] as Map<String, dynamic>? ?? {},
    );
  }
}
