import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Isotipo de OptiLink: dos lunas unidas por un puente, sobre un cuadro
/// redondeado con el degradado de la marca.
class AppLogoMark extends StatelessWidget {
  final double size;

  const AppLogoMark({this.size = 56, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: CustomPaint(painter: _LensesPainter()),
    );
  }
}

class _LensesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.17;
    final centerY = size.height * 0.52;
    final left = Offset(size.width * 0.30, centerY);
    final right = Offset(size.width * 0.70, centerY);

    canvas.drawCircle(left, radius, stroke);
    canvas.drawCircle(right, radius, stroke);

    // Puente entre las dos lunas.
    final bridge = Path()
      ..moveTo(left.dx + radius, centerY - radius * 0.25)
      ..quadraticBezierTo(
        size.width * 0.5,
        centerY - radius * 0.95,
        right.dx - radius,
        centerY - radius * 0.25,
      );
    canvas.drawPath(bridge, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Isotipo con el nombre de la app al lado.
class AppLogo extends StatelessWidget {
  final double markSize;
  final Color textColor;

  const AppLogo({
    this.markSize = 40,
    this.textColor = AppColors.ink,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: markSize),
        SizedBox(width: markSize * 0.3),
        Text(
          'OptiLink',
          style: TextStyle(
            fontSize: markSize * 0.55,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
