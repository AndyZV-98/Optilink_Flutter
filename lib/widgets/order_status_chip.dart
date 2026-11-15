import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pill.dart';

/// Etiqueta de color con el estado de un pedido.
class OrderStatusChip extends StatelessWidget {
  final String status;

  const OrderStatusChip({required this.status, super.key});

  /// Colores (texto y fondo) de cada estado. Los estados desconocidos se
  /// muestran en gris.
  static (Color, Color) colorsFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pendiente':
        return (AppColors.warning, AppColors.warningSoft);
      case 'aprobado':
      case 'confirmado':
      case 'procesando':
        return (AppColors.primary, AppColors.primarySoft);
      case 'enviado':
        return (AppColors.violet, AppColors.violetSoft);
      case 'entregado':
        return (AppColors.success, AppColors.successSoft);
      case 'cancelado':
      case 'rechazado':
        return (AppColors.danger, AppColors.dangerSoft);
      default:
        return (AppColors.muted, AppColors.neutralSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, background) = colorsFor(status);
    return Pill(text: status, color: color, background: background, dot: true);
  }
}
