import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Etiqueta pequeña de bordes redondeados, con fondo suave.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  /// Muestra un punto del color de la etiqueta antes del texto.
  final bool dot;

  const Pill({
    required this.text,
    this.color = AppColors.muted,
    this.background = AppColors.neutralSoft,
    this.dot = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
