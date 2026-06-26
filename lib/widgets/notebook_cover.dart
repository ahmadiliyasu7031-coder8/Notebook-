import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/notebook.dart';

class NotebookCover extends StatelessWidget {
  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final coverColor = AppColors.coverPalette[notebook.coverColorIndex % AppColors.coverPalette.length];
    final hasInfo = !notebook.isEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: coverColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 4)),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.25), width: 1),
        ),
        child: Stack(
          children: [
            // Spine highlight
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  notebook.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.white.withOpacity(0.85),
                  size: 18,
                ),
              ),
            ),
            if (notebook.isLocked)
              const Positioned(
                top: 6,
                left: 16,
                child: Icon(Icons.lock, color: Colors.white70, size: 14),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasInfo ? notebook.name : 'Tap to set up',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasInfo ? notebook.subject : 'NAME / SUBJECT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasInfo)
                        Text(
                          notebook.school,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '60 LEAVES',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
