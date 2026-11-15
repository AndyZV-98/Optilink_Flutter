import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Selector de cantidad: menos, número y más, dentro de una cápsula.
///
/// Un botón sin acción (`null`) se muestra deshabilitado.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final String decrementTooltip;
  final String incrementTooltip;

  /// Versión más pequeña, para las filas del carrito.
  final bool compact;

  const QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementTooltip = 'Restar una unidad',
    this.incrementTooltip = 'Sumar una unidad',
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 36.0 : 44.0;

    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) {
      return IconButton(
        icon: Icon(icon, size: compact ? 18 : 20),
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.ink,
        disabledColor: AppColors.line,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        padding: EdgeInsets.zero,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, decrementTooltip, onDecrement),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 26 : 34),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          button(Icons.add, incrementTooltip, onIncrement),
        ],
      ),
    );
  }
}
