import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra fija inferior para la acción principal de una pantalla.
///
/// Va en `Scaffold.bottomNavigationBar`: así los avisos aparecen encima y no
/// la tapan.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const BottomActionBar({required this.child, this.maxWidth = 720, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
