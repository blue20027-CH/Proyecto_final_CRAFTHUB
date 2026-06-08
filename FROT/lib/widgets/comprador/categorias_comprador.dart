import 'package:flutter/material.dart';

class CategoriasComprador extends StatelessWidget {
  final Color colorVino;

  const CategoriasComprador({
    super.key,
    required this.colorVino,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      ['Textiles', Icons.texture],
      ['Cerámica', Icons.local_cafe_outlined],
      ['Madera', Icons.carpenter_outlined],
      ['Joyería', Icons.diamond_outlined],
      ['Decoración', Icons.spa_outlined],
      ['Accesorios', Icons.widgets_outlined],
      ['Más', Icons.keyboard_arrow_down],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explorar por categorías',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            fontFamily: 'serif',
            color: Color(0xFF3C302B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...categorias.map((categoria) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE4DC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(
                      categoria[1] as IconData,
                      color: colorVino,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoria[0] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C302B),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.location_on_outlined, color: colorVino),
              label: Text(
                'Provincias y comarcas',
                style: TextStyle(
                  color: colorVino,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorVino),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}