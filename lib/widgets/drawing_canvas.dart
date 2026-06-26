import 'package:flutter/material.dart';

import 'drawing_canvas_controller.dart';
import 'strokes_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingCanvasController controller;

  const DrawingCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (controller.pendingStickerEmoji != null) {
                    controller.placeSticker(details.localPosition);
                  }
                },
                onPanStart: (details) {
                  if (controller.pendingStickerEmoji != null) return;
                  controller.startStroke(details.localPosition);
                },
                onPanUpdate: (details) {
                  if (controller.pendingStickerEmoji != null) return;
                  controller.extendStroke(details.localPosition);
                },
                onPanEnd: (_) {
                  if (controller.pendingStickerEmoji != null) return;
                  controller.endStroke();
                },
                child: CustomPaint(
                  painter: StrokesPainter(strokes: controller.strokes, liveStroke: controller.liveStroke),
                  size: Size.infinite,
                ),
              ),
            ),
            for (final sticker in controller.stickers)
              Positioned(
                left: sticker.x - sticker.size / 2,
                top: sticker.y - sticker.size / 2,
                child: GestureDetector(
                  onPanStart: (_) => controller.beginStickerDrag(),
                  onPanUpdate: (details) {
                    controller.moveSticker(
                      sticker.id,
                      Offset(sticker.x + details.delta.dx, sticker.y + details.delta.dy),
                    );
                  },
                  onPanEnd: (_) => controller.commitStickerMove(),
                  onLongPress: () => controller.removeSticker(sticker.id),
                  child: Text(sticker.emoji, style: TextStyle(fontSize: sticker.size)),
                ),
              ),
          ],
        );
      },
    );
  }
}
