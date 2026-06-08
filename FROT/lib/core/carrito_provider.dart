import 'package:flutter/material.dart';
import '../models/carrito_model.dart';

// ============================================================
// PROVEEDOR DEL CARRITO
// Gestiona el estado del carrito activo y la lista de carritos.
// TODO [API]: Reemplazar operaciones mock con llamadas a ApiService
// ============================================================

class CarritoProvider extends ChangeNotifier {
  List<CarritoModel> _carritos = List.from(carritosMock);
  int _indiceCarritoActivo = 0;

  // ── Getters públicos ────────────────────────────────────────
  List<CarritoModel> get carritos => _carritos;
  CarritoModel get carritoActivo => _carritos[_indiceCarritoActivo];
  int get indiceCarritoActivo => _indiceCarritoActivo;

  // ── Cambiar carrito activo ──────────────────────────────────
  // TODO [API]: GET /api/carritos/{carritoId}/items
  void cambiarCarrito(int indice) {
    _indiceCarritoActivo = indice;
    notifyListeners();
  }

  // ── Actualizar cantidad de un ítem ─────────────────────────
  // TODO [API]: PUT /api/carritos/{carritoId}/items/{itemId}
  void actualizarCantidad(int itemId, int nuevaCantidad) {
    final items = carritoActivo.items;
    final indice = items.indexWhere((i) => i.id == itemId);
    if (indice != -1) {
      if (nuevaCantidad <= 0) {
        eliminarItem(itemId);
      } else {
        items[indice].cantidad = nuevaCantidad;
        notifyListeners();
      }
    }
  }

  // ── Eliminar ítem del carrito ───────────────────────────────
  // TODO [API]: DELETE /api/carritos/{carritoId}/items/{itemId}
  void eliminarItem(int itemId) {
    carritoActivo.items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  // ── Vaciar carrito completo ─────────────────────────────────
  // TODO [API]: DELETE /api/carritos/{carritoId}
  void vaciarCarrito() {
    carritoActivo.items.clear();
    notifyListeners();
  }

  // ── Crear nuevo carrito ─────────────────────────────────────
  // TODO [API]: POST /api/carritos  body: { nombre }
  void crearNuevoCarrito(String nombre) {
    final nuevoId = _carritos.length + 1;
    _carritos.add(CarritoModel(
      id: nuevoId,
      nombre: nombre,
      items: [],
      fechaCreacion: DateTime.now(),
    ));
    _indiceCarritoActivo = _carritos.length - 1;
    notifyListeners();
  }

  // ── Descargar factura ───────────────────────────────────────
  // TODO [API]: GET /api/carritos/{carritoId}/factura
  // Retorna un PDF; usar url_launcher o dio para descargarlo
  Future<void> descargarFactura() async {
    // TODO [API]: Implementar descarga real del PDF
    // final url = '${ApiService.baseUrl}/api/carritos/${carritoActivo.id}/factura';
    // await launchUrl(Uri.parse(url));
    debugPrint('Descargando factura del carrito ${carritoActivo.id}...');
  }

  // ── Ver factura completa ────────────────────────────────────
  // TODO [API]: Navegar a pantalla de detalle de factura
  // o abrir WebView con la factura en HTML
  void verFacturaCompleta(BuildContext context) {
    // TODO [API]: Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaFactura(carritoId: carritoActivo.id)));
    debugPrint('Abriendo factura completa del carrito ${carritoActivo.id}...');
  }
}