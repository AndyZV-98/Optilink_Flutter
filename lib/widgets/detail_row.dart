import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fila de etiqueta y valor, para fichas de datos.
class DetailRow extends StatelessWidget {
  final String label;
  final Widget value;
  final IconData? icon;

  const DetailRow({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  /// Fila cuyo valor es texto.
  DetailRow.text({
    required this.label,
    required String value,
    this.icon,
    super.key,
  }) : value = Text(
         value,
         textAlign: TextAlign.right,
         style: const TextStyle(fontWeight: FontWeight.w600),
       );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
          ],
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}
