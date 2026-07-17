import 'dart:convert';

import 'stroke.dart';

class NotebookPage {
  final String id;
  final String notebookId;
  final int pageIndex; // 0..59
  final List<TextRun> textRuns;
  final List<Stroke> strokes;
  final List<StickerPlacement> stickers;
  final bool isBookmarked;
  final int updatedAt;

  NotebookPage({
    required this.id,
    required this.notebookId,
    required this.pageIndex,
    this.textRuns = const [],
    this.strokes = const [],
    this.stickers = const [],
    this.isBookmarked = false,
    required this.updatedAt,
  });

  bool get isBlank => textRuns.every((r) => r.text.trim().isEmpty) && strokes.isEmpty && stickers.isEmpty;

  String get plainText => textRuns.map((r) => r.text).join();

  Map<String, dynamic> toMap() => {
        'id': id,
        'notebook_id': notebookId,
        'page_index': pageIndex,
        'text_runs': jsonEncode(textRuns.map((r) => r.toJson()).toList()),
        'strokes': jsonEncode(strokes.map((s) => s.toJson()).toList()),
        'stickers': jsonEncode(stickers.map((s) => s.toJson()).toList()),
        'is_bookmarked': isBookmarked ? 1 : 0,
        'updated_at': updatedAt,
      };

  factory NotebookPage.fromMap(Map<String, dynamic> map) {
    List<TextRun> runs = [];
    List<Stroke> strokes = [];
    List<StickerPlacement> stickers = [];
    try {
      final rawRuns = jsonDecode(map['text_runs'] as String? ?? '[]') as List;
      runs = rawRuns.map((r) => TextRun.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {}
    try {
      final rawStrokes = jsonDecode(map['strokes'] as String? ?? '[]') as List;
      strokes = rawStrokes.map((s) => Stroke.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {}
    try {
      final rawStickers = jsonDecode(map['stickers'] as String? ?? '[]') as List;
      stickers = rawStickers.map((s) => StickerPlacement.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {}

    return NotebookPage(
      id: map['id'] as String,
      notebookId: map['notebook_id'] as String,
      pageIndex: map['page_index'] as int,
      textRuns: runs,
      strokes: strokes,
      stickers: stickers,
      isBookmarked: (map['is_bookmarked'] as int? ?? 0) == 1,
      updatedAt: map['updated_at'] as int,
    );
  }

  NotebookPage copyWith({
    List<TextRun>? textRuns,
    List<Stroke>? strokes,
    List<StickerPlacement>? stickers,
    bool? isBookmarked,
    int? updatedAt,
  }) {
    return NotebookPage(
      id: id,
      notebookId: notebookId,
      pageIndex: pageIndex,
      textRuns: textRuns ?? this.textRuns,
      strokes: strokes ?? this.strokes,
      stickers: stickers ?? this.stickers,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
