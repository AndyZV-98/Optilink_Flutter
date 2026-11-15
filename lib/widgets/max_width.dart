import 'package:flutter/material.dart';

/// Centra a su hijo y limita su ancho, para que en pantallas grandes (web o
/// tablet) los formularios y listas no se estiren de lado a lado.
class MaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidth({required this.child, this.maxWidth = 720, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
