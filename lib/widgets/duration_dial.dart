// Custom duration dial widget
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class DurationDial extends StatefulWidget {
  final int initialDuration;
  final ValueChanged<int> onChanged;

  const DurationDial({
    super.key,
    required this.initialDuration,
    required this.onChanged,
  });

  @override
  State<DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<DurationDial> {
  late double _angle;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    // Convert duration to angle (0-360 degrees)
    _angle = (_duration / 120) * 2 * math.pi; // Max 2 hours (120 minutes)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final position = details.localPosition;
        final angle =
            (math.atan2(position.dy - center.dy, position.dx - center.dx) +
                math.pi * 2.5) %
            (math.pi * 2);

        setState(() {
          _angle = angle;
          // Convert angle to duration (5-120 minutes)
          _duration = math.max(
            1,
            math.min(120, (angle / (2 * math.pi) * 120).round()),
          );
          widget.onChanged(_duration);
        });
      },
      child: CustomPaint(
        size: const Size(200, 200),
        painter: DialPainter(angle: _angle, duration: _duration),
      ),
    );
  }
}

class DialPainter extends CustomPainter {
  final double angle;
  final int duration;

  DialPainter({required this.angle, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw dial background
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw dial border
    final borderPaint =
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw selected segment
    final selectedPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      angle,
      true,
      selectedPaint,
    );

    // Draw indicator line
    final linePaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    final lineEnd = Offset(
      center.dx + radius * math.cos(angle - math.pi / 2),
      center.dy + radius * math.sin(angle - math.pi / 2),
    );
    canvas.drawLine(center, lineEnd, linePaint);

    // Draw indicator knob
    final knobPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
    canvas.drawCircle(lineEnd, 8, knobPaint);

    // Draw duration text using a simpler approach
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 16,
    );
    final paragraphBuilder =
        ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle.getTextStyle())
          ..addText('$duration min');
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width));
    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.width / 2, center.dy - paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(DialPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.duration != duration;
  }
}
