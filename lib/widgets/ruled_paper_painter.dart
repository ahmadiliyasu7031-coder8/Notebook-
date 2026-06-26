import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Paints the classic exercise-book paper: cream background, evenly
/// spaced blue horizontal rules, and a single red vertical margin line.
/// This is what makes a page look like a real notebook leaf rather than
/// a blank document.
class RuledPaperPainter extends CustomPainter {
  final Color paperColor;
  final Color lineColor;
  final Color marginColor;

  RuledPaperPainter({
    this.paperColor = AppColors.paperCream,
    this.lineColor = AppColors.paperLine,
    this.marginColor = AppColors.marginLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()..color = paperColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paperPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    var y = PaperLayout.topPadding;
    while (y < size.height - 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      y += PaperLayout.lineSpacing;
    }

    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(PaperLayout.marginFromLeft, 0),
      Offset(PaperLayout.marginFromLeft, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RuledPaperPainter oldDelegate) =>
      oldDelegate.paperColor != paperColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.marginColor != marginColor;
}
