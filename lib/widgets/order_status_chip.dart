import 'package:flutter/material.dart';

/// Etiqueta de color con el estado de un pedido.
class OrderStatusChip extends StatelessWidget {
  final String status;

  const OrderStatusChip({required this.status, super.key});

  /// Color asociado a cada estado. Los estados desconocidos se muestran en gris.
  static Color colorFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade800;
      case 'aprobado':
      case 'confirmado':
      case 'procesando':
        return Colors.blue.shade700;
      case 'enviado':
        return Colors.indigo.shade600;
      case 'entregado':
        return Colors.green.shade700;
      case 'cancelado':
      case 'rechazado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
