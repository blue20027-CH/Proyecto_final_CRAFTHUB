import 'package:flutter/material.dart';
import '../../../models/artesano_model.dart';

class ArtesanosDestacados extends StatelessWidget {
  final List<ArtesanoModel> artesanos;
  final Color colorVino;

  const ArtesanosDestacados({
    super.key,
    required this.artesanos,
    required this.colorVino,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artesanos destacados',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'serif',
            color: Color(0xFF3C302B),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: artesanos.map((artesano) {
            return Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorVino, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundImage: AssetImage(artesano.imagen),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colorVino,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  artesano.nombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}