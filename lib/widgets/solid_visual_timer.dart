import 'dart:math';
import 'package:flutter/material.dart';

class SolidVisualTimer extends StatelessWidget {
  final int remaining;
  final int total;

  const SolidVisualTimer({
    Key? key,
    required this.remaining,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : remaining / total;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: SolidCirclePainter(progress),
          child: Center(
            child: Text(
              "$remaining s",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class SolidCirclePainter extends CustomPainter {
  final double progress;

  SolidCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.fill;

    final progressPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      true,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(SolidCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
