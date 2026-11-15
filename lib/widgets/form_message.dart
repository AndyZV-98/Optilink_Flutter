import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Recuadro con un mensaje de error (rojo) o de confirmación (verde) dentro
/// de un formulario.
class FormMessage extends StatelessWidget {
  final String text;
  final bool isError;

  const FormMessage({required this.text, this.isError = true, super.key});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
