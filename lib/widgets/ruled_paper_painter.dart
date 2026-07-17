import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Paints the classic exercise-book paper: cream background, evenly
/// spaced blue horizontal rules, a single red vertical margin line set
/// in from the edge (not overlapping the writing area), faint spiral
/// binding holes down the left edge, and a very subtle paper grain —
/// together this is what makes a page look like a real notebook leaf
/// rather than a blank digital document.
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

    // Subtle paper grain: a sparse, deterministic scatter of near-invisible
    // dots so the page doesn't look like a flat, computer-generated fill.
    var seed = 42;
    int nextRand(int mod) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed % mod;
    }

    final grainDotPaint = Paint()..color = AppColors.textPrimary.withOpacity(0.02);
    final wInt = size.width.toInt().clamp(1, 100000);
    final hInt = size.height.toInt().clamp(1, 100000);
    for (var i = 0; i < 220; i++) {
      final dx = nextRand(wInt).toDouble();
      final dy = nextRand(hInt).toDouble();
      canvas.drawCircle(Offset(dx, dy), 0.5, grainDotPaint);
    }

    // Horizontal ruled lines — thin and faint, like real feint-ruled paper.
    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.55)
      ..strokeWidth = 0.8;

    var y = PaperLayout.topPadding;
    while (y < size.height - 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      y += PaperLayout.lineSpacing;
    }

    // Vertical red margin line — inset from the left edge, thin, and
    // drawn where the writing area begins after it (see
    // PaperLayout.marginFromLeft + the offset used by the page screen)
    // so it never overlaps the writing area.
    final marginPaint = Paint()
      ..color = marginColor.withOpacity(0.75)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(PaperLayout.marginFromLeft, 0),
      Offset(PaperLayout.marginFromLeft, size.height),
      marginPaint,
    );

    // Faint spiral-binding holes down the left edge, matching the
    // notebook's spiral cover art.
    final holePaint = Paint()..color = Colors.black.withOpacity(0.10);
    final holeRingPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const holeSpacing = 46.0;
    const holeRadius = 4.5;
    var holeY = 26.0;
    while (holeY < size.height - 10) {
      final center = Offset(16, holeY);
      canvas.drawCircle(center, holeRadius, holePaint);
      canvas.drawCircle(center, holeRadius + 1.5, holeRingPaint);
      holeY += holeSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant RuledPaperPainter oldDelegate) =>
      oldDelegate.paperColor != paperColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.marginColor != marginColor;
}
