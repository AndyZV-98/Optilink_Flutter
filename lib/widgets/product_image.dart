import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Imagen de un producto. Si no hay URL o no carga, muestra un fondo con el
/// tinte de la marca y el ícono de una luna.
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, Color(0xFFDDF4F3)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.lens_outlined,
        size: iconSize,
        color: AppColors.primary.withValues(alpha: 0.45),
      ),
    );
  }
}
