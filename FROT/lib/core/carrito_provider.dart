import 'package:flutter/material.dart';
import '../models/carrito_model.dart';
import '../services/api_service.dart';
import '../widgets/comprador/dialogo_factura_completa.dart';

class CarritoProvider extends ChangeNotifier {
  List<CarritoModel> _carritos = [];
  int _indiceCarritoActivo = 0;
  String? _userId;
  bool _cargando = false;

  int get indiceCarritoActivo => _indiceCarritoActivo;
  List<CarritoModel> get carritos => _carritos;
  CarritoModel? get carritoActivo => _carritos.isEmpty ? null : _carritos[_indiceCarritoActivo];
  bool get cargando => _cargando;
  String get userId => _userId ?? '';

  Future<void> inicializar(String userId) async {
    _userId = userId;
    Future.microtask(() => cargarCarritos());
  }

  /// Limpia el estado del carrito al cerrar sesión, para que no quede
  /// visible para la siguiente sesión (invitado u otro usuario).
  void cerrarSesion() {
    _userId = null;
    _carritos = [];
    _indiceCarritoActivo = 0;
    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarCarritos() async {
    // Un invitado (userId vacío) no tiene carrito en el backend: no hay
    // nada que cargar, y llamar igual causaba un crash por cast inválido.
    if (_userId == null || _userId!.isEmpty) return;
    _cargando = true;
    try {
      final data = await ApiService.getCarritos(_userId!);
      final lista = (data['carritos'] as List<dynamic>?) ?? [];
      _carritos = lista.map((c) => CarritoModel.fromJson(c)).toList();
      if (_carritos.isEmpty) {
        await _crearCarritoInicial();
      }
    } catch (e) {
      debugPrint('Error cargando carritos: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _crearCarritoInicial() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.crearCarrito(_userId!, 'Mi carrito');
      _carritos.add(CarritoModel.fromJson(data['carrito']));
    } catch (e) {
      debugPrint('Error creando carrito inicial: $e');
    }
  }

  void cambiarCarrito(int indice) {
    _indiceCarritoActivo = indice;
    notifyListeners();
  }

  Future<void> agregarItem({
    required int productoId,
    required String nombreProducto,
    required double precio,
    String imagenUrl = '',
    String artesano = '',
    int cantidad = 1,
  }) async {
    if (carritoActivo == null) return;
    try {
      await ApiService.agregarItem(
        carritoId: carritoActivo!.id,
        productoId: productoId,
        nombreProducto: nombreProducto,
        precio: precio,
        imagenUrl: imagenUrl,
        artesano: artesano,
        cantidad: cantidad,
      );
      await cargarCarritos();
    } catch (e) {
      debugPrint('Error agregando item: $e');
    }
  }

  Future<void> actualizarCantidad(String itemId, int nuevaCantidad) async {
    try {
      await ApiService.actualizarCantidad(itemId, nuevaCantidad);
      await cargarCarritos();
    } catch (e) {
      debugPrint('Error actualizando cantidad: $e');
    }
  }

  Future<void> eliminarItem(String itemId) async {
    try {
      await ApiService.eliminarItem(itemId);
      await cargarCarritos();
    } catch (e) {
      debugPrint('Error eliminando item: $e');
    }
  }

  Future<void> vaciarCarrito() async {
    if (carritoActivo == null) return;
    try {
      await ApiService.vaciarCarrito(carritoActivo!.id);
      await cargarCarritos();
    } catch (e) {
      debugPrint('Error vaciando carrito: $e');
    }
  }

  Future<void> crearNuevoCarrito(String nombre) async {
    if (_userId == null) return;
    try {
      final data = await ApiService.crearCarrito(_userId!, nombre);
      _carritos.add(CarritoModel.fromJson(data['carrito']));
      _indiceCarritoActivo = _carritos.length - 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creando carrito: $e');
    }
  }

  void verFacturaCompleta(BuildContext context) {
    if (carritoActivo == null) return;
    showDialog(
      context: context,
      builder: (_) => DialogoFacturaCompleta(carrito: carritoActivo!),
    );
  }

  Future<void> descargarFactura() async {
    debugPrint('Descargando factura...');
  }
}