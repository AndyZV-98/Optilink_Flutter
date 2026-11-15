import 'package:flutter/material.dart';

/// Centra a su hijo y limita su ancho, para que en pantallas grandes (web o
/// tablet) los formularios y listas no se estiren de lado a lado.
class MaxWidth extends StatelessWidget {
  final double maxWidth;

  /// `true` para ocupar solo el alto del hijo (p. ej. en una barra inferior),
  /// en lugar de todo el alto disponible.
  final bool fitHeight;
  final Widget child;

  const MaxWidth({
    required this.child,
    this.maxWidth = 720,
    this.fitHeight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: fitHeight ? 1 : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
