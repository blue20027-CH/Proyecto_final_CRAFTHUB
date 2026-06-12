// lib/models/modelo_producto_inventario.dart
// Modelo de datos para un producto en el inventario del vendedor

enum EstadoProducto { activo, agotado, borrador }

class ProductoInventario {
  final String id;
  final String sku;
  final String nombre;
  final String coleccion;
  final String categoria;
  final double precio;
  final int stock;
  final int ventas;
  final EstadoProducto estado;
  final String rutaImagen; // Image.asset o URL para Image.network

  const ProductoInventario({
    required this.id,
    required this.sku,
    required this.nombre,
    required this.coleccion,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.ventas,
    required this.estado,
    required this.rutaImagen,
  });

  // 🔌 API: GET /api/vendedor/{vendedorId}/productos
  // Usa este factory para mapear la respuesta JSON del backend
  factory ProductoInventario.fromJson(Map<String, dynamic> json) {
    return ProductoInventario(
      id: json['id'] as String,
      sku: json['sku'] as String,
      nombre: json['nombre'] as String,
      coleccion: json['coleccion'] as String,
      categoria: json['categoria'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      ventas: json['ventas'] as int,
      estado: _estadoDesdeString(json['estado'] as String),
      rutaImagen: json['imagen_url'] as String,
    );
  }

  static EstadoProducto _estadoDesdeString(String s) {
    switch (s) {
      case 'agotado':
        return EstadoProducto.agotado;
      case 'borrador':
        return EstadoProducto.borrador;
      default:
        return EstadoProducto.activo;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'nombre': nombre,
    'coleccion': coleccion,
    'categoria': categoria,
    'precio': precio,
    'stock': stock,
    'ventas': ventas,
    'estado': estado.name,
    'imagen_url': rutaImagen,
  };
}

// Datos mock — reemplazar con respuesta real de la API
List<ProductoInventario> productosMock = [
  const ProductoInventario(
    id: '1',
    sku: 'TEM-001',
    nombre: 'Tembleques Tradicionales',
    coleccion: 'Joyas de mi Tierra',
    categoria: 'Accesorios',
    precio: 28.99,
    stock: 45,
    ventas: 128,
    estado: EstadoProducto.activo,
    rutaImagen: 'assets/productos/tembleques.png',
  ),
  const ProductoInventario(
    id: '2',
    sku: 'BOL-002',
    nombre: 'Bolso Tejido Tradicional',
    coleccion: 'Tejidos Ancestrales',
    categoria: 'Bolsos',
    precio: 75.00,
    stock: 15,
    ventas: 64,
    estado: EstadoProducto.activo,
    rutaImagen: 'assets/productos/bolso_tejido.png',
  ),
  const ProductoInventario(
    id: '3',
    sku: 'MOL-003',
    nombre: 'Mola Guna Floral',
    coleccion: 'Molas Guna',
    categoria: 'Textiles',
    precio: 120.00,
    stock: 8,
    ventas: 29,
    estado: EstadoProducto.activo,
    rutaImagen: 'assets/productos/mola_guna.png',
  ),
  const ProductoInventario(
    id: '4',
    sku: 'CER-004',
    nombre: 'Cerámica Emberá',
    coleccion: 'Raíces y Manos',
    categoria: 'Cerámica',
    precio: 45.00,
    stock: 0,
    ventas: 18,
    estado: EstadoProducto.agotado,
    rutaImagen: 'assets/productos/ceramica_embera.png',
  ),
  const ProductoInventario(
    id: '5',
    sku: 'MAS-005',
    nombre: 'Máscara Tradicional',
    coleccion: 'Arte y Cultura',
    categoria: 'Decoración',
    precio: 89.00,
    stock: 6,
    ventas: 37,
    estado: EstadoProducto.activo,
    rutaImagen: 'assets/productos/mascara.png',
  ),
  const ProductoInventario(
    id: '6',
    sku: 'SOM-006',
    nombre: 'Sombrero Pintao',
    coleccion: 'Tradiciones de Panamá',
    categoria: 'Sombreros',
    precio: 35.00,
    stock: 12,
    ventas: 51,
    estado: EstadoProducto.activo,
    rutaImagen: 'assets/productos/sombrero_pintao.png',
  ),
];
