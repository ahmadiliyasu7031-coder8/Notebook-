import 'dart:ui';

enum DrawTool { pen, pencil, marker, highlighter, eraser, line, circle, rectangle, triangle, arrow }

/// One continuous pen/highlighter/shape stroke on a page.
class Stroke {
  final String id;
  final List<Offset> points; // for shapes: just [start, end]
  final int colorValue;
  final double width;
  final DrawTool tool;

  Stroke({
    required this.id,
    required this.points,
    required this.colorValue,
    required this.width,
    this.tool = DrawTool.pen,
  });

  Color get color => Color(colorValue);
  bool get isHighlighter => tool == DrawTool.highlighter;
  bool get isShape => tool == DrawTool.line ||
      tool == DrawTool.circle ||
      tool == DrawTool.rectangle ||
      tool == DrawTool.triangle ||
      tool == DrawTool.arrow;

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color': colorValue,
        'width': width,
        'tool': tool.name,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        id: json['id'] as String,
        points: (json['points'] as List)
            .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList(),
        colorValue: json['color'] as int,
        width: (json['width'] as num).toDouble(),
        tool: DrawTool.values.firstWhere(
          (t) => t.name == (json['tool'] as String? ?? 'pen'),
          orElse: () => DrawTool.pen,
        ),
      );
}

/// A run of typed text with a single ink color — switching color while
/// typing starts a new run, so typed text can be multi-colored too.
class TextRun {
  final String text;
  final int colorValue;

  TextRun({required this.text, required this.colorValue});

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {'text': text, 'color': colorValue};

  factory TextRun.fromJson(Map<String, dynamic> json) => TextRun(
        text: json['text'] as String,
        colorValue: json['color'] as int,
      );
}

/// A small emoji sticker placed freely on a page (Star, Tick, Warning,
/// Smile, Heart, Question), drag-positioned by the user.
class StickerPlacement {
  final String id;
  final String emoji;
  final double x;
  final double y;
  final double size;

  StickerPlacement({
    required this.id,
    required this.emoji,
    required this.x,
    required this.y,
    this.size = 32,
  });

  Map<String, dynamic> toJson() => {'id': id, 'emoji': emoji, 'x': x, 'y': y, 'size': size};

  factory StickerPlacement.fromJson(Map<String, dynamic> json) => StickerPlacement(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        size: (json['size'] as num?)?.toDouble() ?? 32,
      );

  StickerPlacement copyWith({double? x, double? y}) =>
      StickerPlacement(id: id, emoji: emoji, x: x ?? this.x, y: y ?? this.y, size: size);
}
