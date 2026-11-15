import 'package:flutter/material.dart';

/// Imagen de un producto, con un ícono de reemplazo si no hay URL o no carga.
class ProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double iconSize;

  const ProductImage({
    required this.url,
    this.width,
    this.height,
    this.iconSize = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.lens_outlined, size: iconSize, color: Colors.grey),
    );
  }
}
