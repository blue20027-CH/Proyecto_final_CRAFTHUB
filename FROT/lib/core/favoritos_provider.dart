// lib/core/favoritos_provider.dart
//
// Estado compartido de favoritos (productos y eventos), igual patrón que
// CarritoProvider: cualquier pantalla que marque/desmarque un favorito
// notifica a todos los widgets que estén escuchando (p. ej. la pantalla de
// Favoritos), sin necesidad de salir y volver a entrar para verlo reflejado.

import 'package:flutter/material.dart';
import '../models/evento_modelo.dart';
import '../services/api_service.dart';
import '../services/eventos_api_service.dart';
import '../widgets/comprador/tarjeta_producto.dart';

class FavoritosProvider extends ChangeNotifier {
  String _userId = '';
  List<ProductoModelo> _productos = [];
  List<EventoArtesanal> _eventos = [];
  bool _cargando = false;

  bool get estaLogueado => _userId.isNotEmpty;
  bool get cargando => _cargando;
  List<ProductoModelo> get productos => _productos;
  List<EventoArtesanal> get eventos => _eventos;

  bool esProductoFavorito(String productoId) =>
      _productos.any((p) => p.id == productoId);

  bool esEventoFavorito(String eventoId) =>
      _eventos.any((e) => e.id == eventoId);

  Future<void> inicializar(String userId) async {
    _userId = userId;
    if (!estaLogueado) return;
    // Se difiere a un microtask (igual que CarritoProvider.inicializar) para
    // que el notifyListeners() de cargarFavoritos() no dispare durante la
    // fase de build en la que normalmente se llama esto (initState).
    Future.microtask(() => cargarFavoritos());
  }

  /// Limpia el estado de favoritos al cerrar sesión, para que no queden
  /// visibles para la siguiente sesión (invitado u otro usuario).
  void cerrarSesion() {
    _userId = '';
    _productos = [];
    _eventos = [];
    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarFavoritos() async {
    if (!estaLogueado) return;
    _cargando = true;
    notifyListeners();

    try {
      final data = await ApiService.getFavoritos(_userId);
      _productos = data.map((p) {
        final mapa = Map<String, dynamic>.from(p);
        mapa['id'] = mapa['id'].toString();
        return ProductoModelo.fromJson(mapa);
      }).toList();
    } catch (e) {
      debugPrint('FavoritosProvider: error cargando productos favoritos: $e');
    }

    try {
      _eventos = await EventosApiService.getFavoritos(_userId);
    } catch (e) {
      debugPrint('FavoritosProvider: error cargando eventos favoritos: $e');
    }

    _cargando = false;
    notifyListeners();
  }

  /// Marca/desmarca un producto como favorito. Actualiza la lista local de
  /// inmediato (optimista) y sincroniza con el backend en segundo plano.
  Future<void> alternarProducto(ProductoModelo producto) async {
    final yaEraFavorito = esProductoFavorito(producto.id);
    if (yaEraFavorito) {
      _productos = _productos.where((p) => p.id != producto.id).toList();
    } else {
      _productos = [producto, ..._productos];
    }
    notifyListeners();

    if (!estaLogueado) return;
    final id = int.tryParse(producto.id);
    if (id == null) return;
    try {
      if (yaEraFavorito) {
        await ApiService.quitarFavorito(_userId, id);
      } else {
        await ApiService.agregarFavorito(_userId, id);
      }
    } catch (e) {
      debugPrint('FavoritosProvider: error actualizando favorito de producto: $e');
    }
  }

  /// Marca/desmarca un evento como favorito, con la misma lógica optimista.
  Future<void> alternarEvento(EventoArtesanal evento) async {
    final yaEraFavorito = esEventoFavorito(evento.id);
    if (yaEraFavorito) {
      _eventos = _eventos.where((e) => e.id != evento.id).toList();
    } else {
      _eventos = [evento, ..._eventos];
    }
    notifyListeners();

    if (!estaLogueado) return;
    try {
      await EventosApiService.alternarFavorito(evento.id, _userId, !yaEraFavorito);
    } catch (e) {
      debugPrint('FavoritosProvider: error actualizando favorito de evento: $e');
    }
  }
}
