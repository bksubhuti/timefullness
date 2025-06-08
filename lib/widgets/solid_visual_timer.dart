import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';

class SolidVisualTimer extends StatelessWidget {
  final int remaining;
  final int total;

  const SolidVisualTimer({
    super.key,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final double progress = total == 0 ? 0 : remaining / total;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    String timeStr =
        minutes > 0
            ? "$minutes:${seconds.toString().padLeft(2, '0')}"
            : "$seconds s";

    if (remaining == 0) timeStr = l10n.finished;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSize = min(constraints.maxWidth, 300); // Cap size
        return Center(
          child: SizedBox(
            width: maxSize,
            height: maxSize,
            child: CustomPaint(
              painter: SolidCirclePainter(progress),
              child: Center(
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
          ..color = Color(Prefs.timerColor)
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
