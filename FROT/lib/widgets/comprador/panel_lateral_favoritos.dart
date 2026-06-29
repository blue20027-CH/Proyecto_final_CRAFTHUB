import 'package:flutter/material.dart';


/// Modelo de un carrito guardado del comprador.
/// 🔗 API: GET /api/v1/carritos/{usuarioId} → lista de [ModeloCarritoGuardado]
class ModeloCarritoGuardado {
  final String id;
  final String nombre;
  final int cantidadProductos;
  final double totalEstimado;
  final String rutaImagenPortada; // primer producto del carrito

  const ModeloCarritoGuardado({
    required this.id,
    required this.nombre,
    required this.cantidadProductos,
    required this.totalEstimado,
    required this.rutaImagenPortada,
  });
}

/// Modelo de un artesano seguido.
/// 🔗 API: GET /api/v1/artesanos/seguidos/{usuarioId} → lista de [ModeloArtesanoSeguido]
class ModeloArtesanoSeguido {
  final String id;
  final String nombre;
  final String rutaFoto;
  final String provincia;
  final String categoria;
  final int totalProductos;
  final double calificacion;

  const ModeloArtesanoSeguido({
    required this.id,
    required this.nombre,
    required this.rutaFoto,
    required this.provincia,
    required this.categoria,
    required this.totalProductos,
    required this.calificacion,
  });
}

/// Mensaje vacío reutilizable dentro del panel lateral.
class _MensajeVacioPanelLateral extends StatelessWidget {
  final String mensaje;
  final Color colorSuave;

  const _MensajeVacioPanelLateral({
    required this.mensaje,
    required this.colorSuave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        mensaje,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: colorSuave,
        ),
      ),
    );
  }
}

/// Panel lateral derecho con secciones: Mis Carritos + Artesanos que sigo.
class PanelLateralFavoritos extends StatelessWidget {
  final List<ModeloCarritoGuardado> carritos;
  final List<ModeloArtesanoSeguido> artesanosSeguidos;
  final VoidCallback alCrearNuevoCarrito;
  final VoidCallback alVerTodosLosArtesanos;

  const PanelLateralFavoritos({
    super.key,
    required this.carritos,
    required this.artesanosSeguidos,
    required this.alCrearNuevoCarrito,
    required this.alVerTodosLosArtesanos,
  });

  static const _colorVino = Color(0xFF821515);

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondoTarjeta =
        esTemaOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorTextoSuave =
        esTemaOscuro ? Colors.white54 : Colors.black45;

    return Column(
      children: [
        // ── Mis Carritos ──────────────────────────────────────────
        _SeccionPanel(
          titulo: 'Mis carritos',
          icono: Icons.shopping_cart_outlined,
          etiquetaAccion: 'Nuevo',
          onAccion: alCrearNuevoCarrito,
          child: carritos.isEmpty
              ? _MensajeVacioPanelLateral(
                  mensaje: 'No tienes carritos aún.',
                  colorSuave: colorTextoSuave,
                )
              : Column(
                  children: carritos
                      .take(3)
                      .map((c) => _TarjetaCarrito(
                            carrito: c,
                            colorFondo: colorFondoTarjeta,
                            colorSuave: colorTextoSuave,
                          ))
                      .toList(),
                ),
        ),

        const SizedBox(height: 16),

        // ── Artesanos que sigo ─────────────────────────────────────
        _SeccionPanel(
          titulo: 'Artesanos que sigues',
          icono: Icons.person_outline,
          etiquetaAccion: 'Ver todos',
          onAccion: alVerTodosLosArtesanos,
          child: artesanosSeguidos.isEmpty
              ? _MensajeVacioPanelLateral(
                  mensaje: 'Aún no sigues artesanos.',
                  colorSuave: colorTextoSuave,
                )
              : Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: artesanosSeguidos
                      .take(4)
                      .map((a) => _AvatarArtesano(artesano: a))
                      .toList(),
                ),
        ),

        const SizedBox(height: 16),

        // ── CTA: Te encanta algo ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: esTemaOscuro
                ? const Color(0xFF2A1010)
                : const Color(0xFFFDF0F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _colorVino.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      color: _colorVino, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '¿Te encanta algo?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _colorVino,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Agrégalo al carrito y apóyalo con tu compra.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorTextoSuave,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 🔗 API: navegar al carrito activo → GET /api/v1/carrito/activo/{usuarioId}
                  },
                  icon: const Icon(Icons.shopping_cart_outlined,
                      size: 16),
                  label: const Text(
                    'Ir al carrito',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorVino,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sección reutilizable del panel lateral con título, ícono y acción.
class _SeccionPanel extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String etiquetaAccion;
  final VoidCallback onAccion;
  final Widget child;

  const _SeccionPanel({
    required this.titulo,
    required this.icono,
    required this.etiquetaAccion,
    required this.onAccion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esTemaOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esTemaOscuro ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: const Color(0xFF821515)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAccion,
                child: Text(
                  etiquetaAccion,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF821515),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Tarjeta individual de un carrito guardado.
class _TarjetaCarrito extends StatelessWidget {
  final ModeloCarritoGuardado carrito;
  final Color colorFondo;
  final Color colorSuave;

  const _TarjetaCarrito({
    required this.carrito,
    required this.colorFondo,
    required this.colorSuave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Miniatura del carrito
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Image.asset(
                carrito.rutaImagenPortada,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF821515).withValues(alpha: 0.15),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFF821515), size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrito.nombre,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${carrito.cantidadProductos} productos',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colorSuave,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${carrito.totalEstimado.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF821515),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular de artesano con nombre debajo.
class _AvatarArtesano extends StatelessWidget {
  final ModeloArtesanoSeguido artesano;

  const _AvatarArtesano({required this.artesano});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(artesano.rutaFoto),
              backgroundColor: const Color(0xFF821515).withValues(alpha: 0.15),
              onBackgroundImageError: (_, _) {},
              child: Icon(Icons.person,
                  color: const Color(0xFF821515).withValues(alpha: 0.5)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF821515),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite,
                    color: Colors.white, size: 9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            artesano.nombre.split(' ').first,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}