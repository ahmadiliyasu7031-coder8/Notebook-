import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../models/notebook.dart';
import '../models/notebook_page.dart';
import '../models/stroke.dart';

/// Renders notebook pages to a PDF, replicating the ruled-paper look and
/// strokes using the pdf package's low-level PdfGraphics primitives
/// (moveTo/lineTo/strokePath), which are guaranteed stable across
/// versions — text content is rendered as a single flowing paragraph
/// per page (multi-color runs are simplified to the page's last-used
/// ink color in the PDF export specifically; the on-screen app keeps
/// full multi-color fidelity).
class PdfExportService {
  static Future<void> exportAndShare(Notebook notebook, List<NotebookPage> pages) async {
    final doc = pw.Document();
    final sortedPages = [...pages]..sort((a, b) => a.pageIndex.compareTo(b.pageIndex));

    for (final page in sortedPages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.CustomPaint(
                  painter: (canvas, size) => _paintPage(canvas, size, page),
                ),
              ),
              pw.Positioned(
                left: 60,
                top: 40,
                right: 20,
                child: pw.Text(
                  page.plainText,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: page.textRuns.isNotEmpty
                        ? PdfColor.fromInt(page.textRuns.last.colorValue)
                        : PdfColors.black,
                  ),
                ),
              ),
              pw.Positioned(
                bottom: 10,
                right: 16,
                child: pw.Text('Created by Ahmad Iliyasu',
                    style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey)),
              ),
              pw.Positioned(
                top: 8,
                right: 16,
                child: pw.Text('Page ${page.pageIndex + 1}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeName = notebook.name.isEmpty ? 'notebook' : notebook.name.replaceAll(RegExp(r'[^\w\s-]'), '');
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        text: '${notebook.name} — exported from Pocket Exercise Book',
        files: [XFile(file.path)],
      ),
    );
  }

  static void _paintPage(PdfGraphics canvas, PdfPoint size, NotebookPage page) {
    // Ruled lines
    canvas.setStrokeColor(PdfColor.fromInt(AppColors.paperLine.value));
    canvas.setLineWidth(0.4);
    var y = size.y - 60; // PDF origin is bottom-left, so start near the top
    while (y > 20) {
      canvas.moveTo(15, y);
      canvas.lineTo(size.x - 15, y);
      canvas.strokePath();
      y -= 22;
    }

    // Margin line
    canvas.setStrokeColor(PdfColor.fromInt(AppColors.marginLine.value));
    canvas.setLineWidth(0.6);
    canvas.moveTo(50, 10);
    canvas.lineTo(50, size.y - 10);
    canvas.strokePath();

    // Strokes — flip Y since on-screen (0,0) is top-left but PDF (0,0)
    // is bottom-left.
    for (final stroke in page.strokes) {
      if (stroke.points.isEmpty) continue;
      canvas.setStrokeColor(PdfColor.fromInt(stroke.colorValue));
      canvas.setLineWidth(stroke.width * 0.5);

      if (stroke.isShape && stroke.points.length >= 2) {
        final start = stroke.points.first;
        final end = stroke.points.last;
        switch (stroke.tool) {
          case DrawTool.circle:
            _strokeApproximateEllipse(canvas, start, end, size.y);
            break;
          case DrawTool.rectangle:
            canvas.moveTo(start.dx, size.y - start.dy);
            canvas.lineTo(end.dx, size.y - start.dy);
            canvas.lineTo(end.dx, size.y - end.dy);
            canvas.lineTo(start.dx, size.y - end.dy);
            canvas.lineTo(start.dx, size.y - start.dy);
            canvas.strokePath();
            break;
          default:
            canvas.moveTo(start.dx, size.y - start.dy);
            canvas.lineTo(end.dx, size.y - end.dy);
            canvas.strokePath();
        }
        continue;
      }

      canvas.moveTo(stroke.points.first.dx, size.y - stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        canvas.lineTo(point.dx, size.y - point.dy);
      }
      canvas.strokePath();
    }
  }

  static void _strokeApproximateEllipse(PdfGraphics canvas, Offset start, Offset end, double pageHeight) {
    final cx = (start.dx + end.dx) / 2;
    final cy = (start.dy + end.dy) / 2;
    final rx = (end.dx - start.dx).abs() / 2;
    final ry = (end.dy - start.dy).abs() / 2;
    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final theta = (i / segments) * 2 * math.pi;
      final x = cx + rx * math.cos(theta);
      final y = cy + ry * math.sin(theta);
      if (i == 0) {
        canvas.moveTo(x, pageHeight - y);
      } else {
        canvas.lineTo(x, pageHeight - y);
      }
    }
    canvas.strokePath();
  }
}
