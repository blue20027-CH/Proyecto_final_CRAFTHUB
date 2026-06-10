import 'package:flutter/material.dart';

class CompradorTopbar extends StatelessWidget {
  final Color colorVino;
  final VoidCallback? onIrAMapa; // ← agrega

  const CompradorTopbar({
    super.key,
    required this.colorVino,
    this.onIrAMapa, // ← agrega
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 520,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos, artesanos...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Color(0xFFE2D8D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Color(0xFFE2D8D0)),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.calendar_month_outlined),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.favorite, color: colorVino),
        ),
      ],
    );
  }
}