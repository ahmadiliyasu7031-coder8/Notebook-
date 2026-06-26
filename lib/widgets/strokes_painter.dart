import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/stroke.dart';

class StrokesPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? liveStroke;

  StrokesPainter({required this.strokes, this.liveStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (liveStroke != null) _paintStroke(canvas, liveStroke!);
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = stroke.isShape ? PaintingStyle.stroke : PaintingStyle.stroke;

    if (stroke.isShape) {
      if (stroke.points.length < 2) return;
      final start = stroke.points.first;
      final end = stroke.points.last;
      final rect = Rect.fromPoints(start, end);
      switch (stroke.tool) {
        case DrawTool.line:
          canvas.drawLine(start, end, paint);
          break;
        case DrawTool.circle:
          canvas.drawOval(rect, paint);
          break;
        case DrawTool.rectangle:
          canvas.drawRect(rect, paint);
          break;
        case DrawTool.triangle:
          final path = Path()
            ..moveTo((start.dx + end.dx) / 2, start.dy)
            ..lineTo(start.dx, end.dy)
            ..lineTo(end.dx, end.dy)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case DrawTool.arrow:
          canvas.drawLine(start, end, paint);
          final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
          const arrowLength = 14.0;
          const arrowAngle = 0.5;
          final p1 = Offset(
            end.dx - arrowLength * math.cos(angle - arrowAngle),
            end.dy - arrowLength * math.sin(angle - arrowAngle),
          );
          final p2 = Offset(
            end.dx - arrowLength * math.cos(angle + arrowAngle),
            end.dy - arrowLength * math.sin(angle + arrowAngle),
          );
          canvas.drawLine(end, p1, paint);
          canvas.drawLine(end, p2, paint);
          break;
        default:
          break;
      }
      return;
    }

    if (stroke.points.length == 1) {
      // A single tap with no drag — draw a dot so it's still visible.
      canvas.drawCircle(stroke.points.first, stroke.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.liveStroke != liveStroke;
}
