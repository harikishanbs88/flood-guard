import 'package:flutter/material.dart';

class JalKavachLogo extends StatelessWidget {
  final double size;

  const JalKavachLogo({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.92,
      child: CustomPaint(
        painter: _JalKavachLogoPainter(),
      ),
    );
  }
}

class _JalKavachLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shieldPaint = Paint()
      ..color = const Color(0xFF0E2E6D)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = const Color(0xFF1D4F9C)
      ..style = PaintingStyle.fill;

    final wavePaint = Paint()
      ..color = const Color(0xFF9DE5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()..color = Colors.black12;

    final shieldPath = Path()
      ..moveTo(size.width * 0.18, 0)
      ..lineTo(size.width * 0.82, 0)
      ..lineTo(size.width * 0.96, size.height * 0.24)
      ..lineTo(size.width * 0.84, size.height)
      ..lineTo(size.width * 0.5, size.height * 0.96)
      ..lineTo(size.width * 0.16, size.height)
      ..lineTo(size.width * 0.04, size.height * 0.24)
      ..close();

    final innerShieldPath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.08)
      ..lineTo(size.width * 0.76, size.height * 0.08)
      ..lineTo(size.width * 0.88, size.height * 0.26)
      ..lineTo(size.width * 0.76, size.height * 0.9)
      ..lineTo(size.width * 0.5, size.height * 0.86)
      ..lineTo(size.width * 0.24, size.height * 0.9)
      ..lineTo(size.width * 0.12, size.height * 0.26)
      ..close();

    canvas.drawPath(shieldPath, shadowPaint);
    canvas.drawPath(shieldPath, shieldPaint);
    canvas.drawPath(innerShieldPath, innerPaint);

    final wavePath1 = Path()
      ..moveTo(size.width * 0.14, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.62,
        size.width * 0.38,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.78,
        size.width * 0.62,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.62,
        size.width * 0.86,
        size.height * 0.70,
      );

    final wavePath2 = Path()
      ..moveTo(size.width * 0.10, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.74,
        size.width * 0.36,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.90,
        size.width * 0.64,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.74,
        size.width * 0.90,
        size.height * 0.82,
      );

    canvas.drawPath(wavePath1, wavePaint);
    canvas.drawPath(wavePath2, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
