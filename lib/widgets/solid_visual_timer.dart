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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool isBypassing = Prefs.oneHourDisplay && remaining > 3600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double progress =
        (Prefs.oneHourDisplay && remaining <= 3600)
            ? remaining / 3600
            : (total == 0 ? 0 : remaining / total);

    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    String timeStr =
        minutes > 0
            ? "$minutes:${seconds.toString().padLeft(2, '0')}"
            : "$seconds s";

    if (remaining == 0) timeStr = l10n.finished;

    final textColor = isDark ? Colors.white : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSize = min(constraints.maxWidth, 300);
        return Center(
          child: Column(
            children: [
              SizedBox(
                width: maxSize,
                height: maxSize,
                child: CustomPaint(
                  painter: SolidCirclePainter(progress, isDark),
                  child: Center(
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isBypassing)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.timerBypassMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SolidCirclePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  SolidCirclePainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade300
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
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
