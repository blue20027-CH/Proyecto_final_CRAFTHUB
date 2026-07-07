// lib/services/exportador_inventario.dart
// Exporta el inventario del vendedor a un archivo CSV real (nada de mock):
// arma el CSV a partir de la lista de productos ya cargada y deja que el
// vendedor elija dónde guardarlo con el selector nativo de archivos.
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/modelo_producto_inventario.dart';

class ExportadorInventario {
  static Future<void> exportarCsv(List<ProductoInventario> productos) async {
    final buffer = StringBuffer();
    buffer.writeln('SKU,Nombre,Colección,Categoría,Precio,Stock,Ventas,Estado');
    for (final p in productos) {
      buffer.writeln([
        _celda(p.sku),
        _celda(p.nombre),
        _celda(p.coleccion),
        _celda(p.categoria),
        p.precio.toStringAsFixed(2),
        p.stock,
        p.ventas,
        _celda(p.estado.name),
      ].join(','));
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final nombreArchivo =
        'inventario_crafthub_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

    final ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar inventario como CSV',
      fileName: nombreArchivo,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (ruta == null) {
      throw Exception('Exportación cancelada.');
    }
  }

  // Escapa comas/comillas para que el CSV no se rompa con nombres como
  // "Bolso, tejido a mano" o con comillas dentro del texto.
  static String _celda(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }
}
