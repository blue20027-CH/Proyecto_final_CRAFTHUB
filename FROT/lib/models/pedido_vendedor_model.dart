// lib/models/pedido_vendedor_model.dart
// Modelos para la pantalla de Órdenes y el mapa de pedidos del vendedor.

class ItemPedidoVendedor {
  final String nombre;
  final String imagenUrl;
  final int cantidad;

  const ItemPedidoVendedor({
    required this.nombre,
    required this.imagenUrl,
    required this.cantidad,
  });

  factory ItemPedidoVendedor.fromJson(Map<String, dynamic> json) {
    return ItemPedidoVendedor(
      nombre: (json['nombre'] ?? 'Producto').toString(),
      imagenUrl: (json['imagen_url'] ?? '').toString(),
      cantidad: int.tryParse((json['cantidad'] ?? 1).toString()) ?? 1,
    );
  }
}

/// Estados canónicos que devuelve el backend (coinciden con la BD).
class EstadoPedido {
  static const String pendiente = 'pendiente';
  static const String aceptada = 'en proceso';
  static const String enviado = 'enviado';
  static const String completada = 'entregado';
  static const String cancelada = 'cancelado';

  static const List<String> todos = [
    pendiente,
    aceptada,
    enviado,
    completada,
    cancelada,
  ];

  static String etiqueta(String estado) {
    switch (estado) {
      case aceptada:
        return 'Aceptada';
      case enviado:
        return 'Enviado';
      case completada:
        return 'Completada';
      case cancelada:
        return 'Cancelada';
      case pendiente:
      default:
        return 'Pendiente';
    }
  }

  static String etiquetaMapa(String estado) {
    switch (estado) {
      case aceptada:
        return 'Aceptada';
      case enviado:
        return 'En camino';
      case completada:
        return 'Entregado';
      case cancelada:
        return 'Cancelado';
      case pendiente:
      default:
        return 'Pendiente';
    }
  }
}

class PedidoVendedor {
  final String id;
  final String orden;
  final String clienteNombre;
  final String? clienteId;
  final String ubicacion;
  final String? telefono;
  final List<ItemPedidoVendedor> productos;
  final int cantidadProductos;
  final double total;
  final String estado;
  final String estadoLabel;
  final DateTime? fecha;

  const PedidoVendedor({
    required this.id,
    required this.orden,
    required this.clienteNombre,
    required this.clienteId,
    required this.ubicacion,
    required this.telefono,
    required this.productos,
    required this.cantidadProductos,
    required this.total,
    required this.estado,
    required this.estadoLabel,
    required this.fecha,
  });

  factory PedidoVendedor.fromJson(Map<String, dynamic> json) {
    final productosJson = (json['productos'] as List?) ?? [];
    return PedidoVendedor(
      id: (json['id'] ?? '').toString(),
      orden: (json['orden'] ?? '').toString(),
      clienteNombre: (json['cliente_nombre'] ?? 'Cliente').toString(),
      clienteId: json['cliente_id']?.toString(),
      ubicacion: (json['ubicacion'] ?? 'Panamá').toString(),
      telefono: json['telefono']?.toString(),
      productos: productosJson
          .map((p) => ItemPedidoVendedor.fromJson(p as Map<String, dynamic>))
          .toList(),
      cantidadProductos:
          int.tryParse((json['cantidad_productos'] ?? 0).toString()) ?? 0,
      total: double.tryParse((json['total'] ?? 0).toString()) ?? 0,
      estado: (json['estado'] ?? 'pendiente').toString(),
      estadoLabel: (json['estado_label'] ?? 'Pendiente').toString(),
      fecha: DateTime.tryParse((json['fecha'] ?? '').toString()),
    );
  }

  PedidoVendedor copyWith({String? estado, String? estadoLabel}) {
    return PedidoVendedor(
      id: id,
      orden: orden,
      clienteNombre: clienteNombre,
      clienteId: clienteId,
      ubicacion: ubicacion,
      telefono: telefono,
      productos: productos,
      cantidadProductos: cantidadProductos,
      total: total,
      estado: estado ?? this.estado,
      estadoLabel: estadoLabel ?? this.estadoLabel,
      fecha: fecha,
    );
  }
}

class EstadisticasPedidosVendedor {
  final int totalOrdenes;
  final int nuevasOrdenes;
  final int completadas;
  final int canceladas;
  final double ingresosTotales;

  const EstadisticasPedidosVendedor({
    required this.totalOrdenes,
    required this.nuevasOrdenes,
    required this.completadas,
    required this.canceladas,
    required this.ingresosTotales,
  });

  factory EstadisticasPedidosVendedor.fromJson(Map<String, dynamic> json) {
    return EstadisticasPedidosVendedor(
      totalOrdenes: int.tryParse((json['total_ordenes'] ?? 0).toString()) ?? 0,
      nuevasOrdenes:
          int.tryParse((json['nuevas_ordenes'] ?? 0).toString()) ?? 0,
      completadas: int.tryParse((json['completadas'] ?? 0).toString()) ?? 0,
      canceladas: int.tryParse((json['canceladas'] ?? 0).toString()) ?? 0,
      ingresosTotales:
          double.tryParse((json['ingresos_totales'] ?? 0).toString()) ?? 0,
    );
  }

  static const vacio = EstadisticasPedidosVendedor(
    totalOrdenes: 0,
    nuevasOrdenes: 0,
    completadas: 0,
    canceladas: 0,
    ingresosTotales: 0,
  );
}

class RespuestaPedidosVendedor {
  final List<PedidoVendedor> pedidos;
  final EstadisticasPedidosVendedor estadisticas;

  const RespuestaPedidosVendedor({
    required this.pedidos,
    required this.estadisticas,
  });
}

class PuntoMapaPedido {
  final String id;
  final String orden;
  final String clienteNombre;
  final String ubicacion;
  final double lat;
  final double lng;
  final String estado;
  final String estadoLabel;
  final double total;
  final String? telefono;
  final DateTime? fecha;

  const PuntoMapaPedido({
    required this.id,
    required this.orden,
    required this.clienteNombre,
    required this.ubicacion,
    required this.lat,
    required this.lng,
    required this.estado,
    required this.estadoLabel,
    required this.total,
    required this.telefono,
    required this.fecha,
  });

  factory PuntoMapaPedido.fromJson(Map<String, dynamic> json) {
    return PuntoMapaPedido(
      id: (json['id'] ?? '').toString(),
      orden: (json['orden'] ?? '').toString(),
      clienteNombre: (json['cliente_nombre'] ?? 'Cliente').toString(),
      ubicacion: (json['ubicacion'] ?? 'Panamá').toString(),
      lat: double.tryParse((json['lat'] ?? 0).toString()) ?? 0,
      lng: double.tryParse((json['lng'] ?? 0).toString()) ?? 0,
      estado: (json['estado'] ?? 'pendiente').toString(),
      estadoLabel: (json['estado_label'] ?? 'Pendiente').toString(),
      total: double.tryParse((json['total'] ?? 0).toString()) ?? 0,
      telefono: json['telefono']?.toString(),
      fecha: DateTime.tryParse((json['fecha'] ?? '').toString()),
    );
  }
}
