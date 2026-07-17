import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/stroke.dart';

const _uuid = Uuid();

/// Holds all drawable state for one page (strokes + stickers), the
/// currently selected tool/color/width, and a simple snapshot-based
/// undo/redo stack. Pages aren't large enough for snapshotting to be
/// a real memory concern.
class DrawingCanvasController extends ChangeNotifier {
  List<Stroke> strokes;
  List<StickerPlacement> stickers;

  DrawTool tool = DrawTool.pen;
  Color color = AppColors.inkBlue;
  double width = 3.0;
  String? pendingStickerEmoji;

  final List<({List<Stroke> strokes, List<StickerPlacement> stickers})> _undoStack = [];
  final List<({List<Stroke> strokes, List<StickerPlacement> stickers})> _redoStack = [];

  Stroke? _liveStroke;
  Stroke? get liveStroke => _liveStroke;

  void Function()? onChanged;

  DrawingCanvasController({List<Stroke>? strokes, List<StickerPlacement>? stickers})
      : strokes = List.of(strokes ?? []),
        stickers = List.of(stickers ?? []);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndoSnapshot() {
    _undoStack.add((strokes: List.of(strokes), stickers: List.of(stickers)));
    _redoStack.clear();
    // Bound memory: keep at most 30 undo steps per page.
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add((strokes: List.of(strokes), stickers: List.of(stickers)));
    final snap = _undoStack.removeLast();
    strokes = List.of(snap.strokes);
    stickers = List.of(snap.stickers);
    notifyListeners();
    onChanged?.call();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add((strokes: List.of(strokes), stickers: List.of(stickers)));
    final snap = _redoStack.removeLast();
    strokes = List.of(snap.strokes);
    stickers = List.of(snap.stickers);
    notifyListeners();
    onChanged?.call();
  }

  // --- Freehand / shape drawing lifecycle ---

  void startStroke(Offset point) {
    if (tool == DrawTool.eraser) {
      _eraseAt(point);
      return;
    }
    _liveStroke = Stroke(
      id: _uuid.v4(),
      points: [point],
      colorValue: (tool == DrawTool.highlighter ? color.withOpacity(0.4) : color).value,
      width: tool == DrawTool.highlighter ? width * 4 : width,
      tool: tool,
    );
    notifyListeners();
  }

  void extendStroke(Offset point) {
    final live = _liveStroke;
    if (live == null) {
      if (tool == DrawTool.eraser) _eraseAt(point);
      return;
    }
    if (live.isShape) {
      // Shapes only ever need a start + current end point.
      _liveStroke = Stroke(
        id: live.id,
        points: [live.points.first, point],
        colorValue: live.colorValue,
        width: live.width,
        tool: live.tool,
      );
    } else {
      _liveStroke = Stroke(
        id: live.id,
        points: [...live.points, point],
        colorValue: live.colorValue,
        width: live.width,
        tool: live.tool,
      );
    }
    notifyListeners();
  }

  void endStroke() {
    final live = _liveStroke;
    if (live == null) return;
    _pushUndoSnapshot();
    strokes = [...strokes, live];
    _liveStroke = null;
    notifyListeners();
    onChanged?.call();
  }

  void _eraseAt(Offset point) {
    const eraseRadius = 18.0;
    final toRemove = strokes.where((s) => s.points.any((p) => (p - point).distance < eraseRadius));
    if (toRemove.isEmpty) return;
    _pushUndoSnapshot();
    final removeIds = toRemove.map((s) => s.id).toSet();
    strokes = strokes.where((s) => !removeIds.contains(s.id)).toList();
    notifyListeners();
    onChanged?.call();
  }

  // --- Stickers ---

  void placeSticker(Offset point) {
    final emoji = pendingStickerEmoji;
    if (emoji == null) return;
    _pushUndoSnapshot();
    stickers = [
      ...stickers,
      StickerPlacement(id: _uuid.v4(), emoji: emoji, x: point.dx, y: point.dy),
    ];
    pendingStickerEmoji = null;
    notifyListeners();
    onChanged?.call();
  }

  void beginStickerDrag() {
    _pushUndoSnapshot();
  }

  void moveSticker(String id, Offset newPosition) {
    stickers = stickers
        .map((s) => s.id == id ? s.copyWith(x: newPosition.dx, y: newPosition.dy) : s)
        .toList();
    notifyListeners();
  }

  void commitStickerMove() {
    onChanged?.call();
  }

  void removeSticker(String id) {
    _pushUndoSnapshot();
    stickers = stickers.where((s) => s.id != id).toList();
    notifyListeners();
    onChanged?.call();
  }
}
