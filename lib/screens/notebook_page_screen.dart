import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../database/page_repository.dart';
import '../models/notebook.dart';
import '../models/notebook_page.dart';
import '../models/stroke.dart';
import '../providers/notebook_providers.dart';
import '../services/pdf_export_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_canvas_controller.dart';
import '../widgets/ruled_paper_painter.dart';
import 'lock_screen.dart';

enum InputMode { typing, drawing }

class NotebookPageScreen extends ConsumerStatefulWidget {
  final Notebook notebook;

  const NotebookPageScreen({super.key, required this.notebook});

  @override
  ConsumerState<NotebookPageScreen> createState() => _NotebookPageScreenState();
}

class _NotebookPageScreenState extends ConsumerState<NotebookPageScreen> {
  final _pageRepo = PageRepository();
  late final PageController _pageController;
  late int _currentIndex;
  InputMode _mode = InputMode.typing;
  DrawTool _tool = DrawTool.pen;
  Color _color = AppColors.inkBlue;
  double _penWidth = 3.0;
  bool _unlocked = false;
  bool _checkingLock = true;

  final Map<int, NotebookPage> _pages = {};
  final Map<int, DrawingCanvasController> _controllers = {};
  final Map<int, TextEditingController> _textControllers = {};
  final Map<int, int> _runBoundary = {}; // offset where the "active" (last) run begins
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.notebook.lastPageIndex.clamp(0, PaperLayout.totalLeaves - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _checkLock();
  }

  Future<void> _checkLock() async {
    if (!widget.notebook.isLocked) {
      setState(() {
        _unlocked = true;
        _checkingLock = false;
      });
      await _loadPage(_currentIndex);
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LockScreen(notebook: widget.notebook)),
    );
    if (!mounted) return;
    if (ok == true) {
      setState(() {
        _unlocked = true;
        _checkingLock = false;
      });
      await _loadPage(_currentIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pageController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPage(int index) async {
    if (_pages.containsKey(index)) return;
    final page = await _pageRepo.getOrCreate(widget.notebook.id, index);
    if (!mounted) return;
    setState(() {
      _pages[index] = page;
      _controllers[index] = DrawingCanvasController(strokes: page.strokes, stickers: page.stickers)
        ..tool = _tool
        ..color = _color
        ..width = _penWidth
        ..onChanged = () => _scheduleSave(index);
      final textController = TextEditingController(text: page.plainText);
      _textControllers[index] = textController;
      _runBoundary[index] = page.textRuns.isEmpty
          ? 0
          : page.plainText.length - page.textRuns.last.text.length;
    });
  }

  void _scheduleSave(int index) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () => _save(index));
  }

  Future<void> _save(int index) async {
    final existing = _pages[index];
    final canvas = _controllers[index];
    final textController = _textControllers[index];
    if (existing == null || canvas == null || textController == null) return;

    final runs = _buildRuns(index, textController.text);
    final updated = existing.copyWith(
      textRuns: runs,
      strokes: canvas.strokes,
      stickers: canvas.stickers,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _pages[index] = updated;
    await _pageRepo.save(updated);

    // Remember where the user left off.
    final repo = ref.read(notebookRepositoryProvider);
    final fresh = await repo.getById(widget.notebook.id);
    if (fresh != null) {
      await repo.update(fresh.copyWith(lastPageIndex: index));
    }
  }

  /// Rebuilds the run list for a page: everything before the tracked
  /// boundary is frozen (already-committed runs/colors), everything
  /// from the boundary onward is one live run in the current color.
  /// (Known simplification: editing text earlier in the page rather
  /// than only appending can desync which color applies where — fine
  /// for an exercise-book-style "write forward" workflow.)
  List<TextRun> _buildRuns(int index, String fullText) {
    final page = _pages[index];
    final boundary = _runBoundary[index] ?? 0;
    final frozenRuns = <TextRun>[];
    if (page != null) {
      var consumed = 0;
      for (final run in page.textRuns) {
        if (consumed + run.text.length <= boundary) {
          frozenRuns.add(run);
          consumed += run.text.length;
        } else {
          break;
        }
      }
    }
    final frozenLength = frozenRuns.fold<int>(0, (sum, r) => sum + r.text.length);
    final liveText = fullText.length >= frozenLength ? fullText.substring(frozenLength) : '';
    final runs = [...frozenRuns];
    if (liveText.isNotEmpty) {
      runs.add(TextRun(text: liveText, colorValue: _color.value));
    }
    return runs;
  }

  void _onColorChanged(Color color) {
    setState(() => _color = color);
    final canvas = _controllers[_currentIndex];
    if (canvas != null) canvas.color = color;
    if (_mode == InputMode.typing) {
      final textController = _textControllers[_currentIndex];
      if (textController != null) {
        _runBoundary[_currentIndex] = textController.text.length;
      }
    }
  }

  void _changePage(int index) async {
    await _save(_currentIndex);
    setState(() => _currentIndex = index);
    await _loadPage(index);
  }

  Future<void> _toggleBookmark() async {
    final page = _pages[_currentIndex];
    if (page == null) return;
    final updated = page.copyWith(isBookmarked: !page.isBookmarked);
    setState(() => _pages[_currentIndex] = updated);
    await _pageRepo.save(updated);
  }

  Future<void> _exportPdf({bool currentPageOnly = false}) async {
    final allPages = await _pageRepo.getAllForNotebook(widget.notebook.id);
    final pagesToExport =
        currentPageOnly ? allPages.where((p) => p.pageIndex == _currentIndex).toList() : allPages;
    if (!mounted) return;
    await PdfExportService.exportAndShare(widget.notebook, pagesToExport);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLock) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_unlocked) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.coverBrown,
      appBar: AppBar(
        backgroundColor: AppColors.coverBrown,
        foregroundColor: Colors.white,
        title: Text(widget.notebook.name.isEmpty ? 'Notebook' : widget.notebook.name),
        actions: [
          IconButton(
            icon: Icon(
              (_pages[_currentIndex]?.isBookmarked ?? false) ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export_page':
                  _exportPdf(currentPageOnly: true);
                  break;
                case 'export_all':
                  _exportPdf();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export_page', child: Text('Export This Page (PDF)')),
              PopupMenuItem(value: 'export_all', child: Text('Export Whole Notebook (PDF)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: PaperLayout.totalLeaves,
              onPageChanged: _changePage,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page ?? _currentIndex.toDouble()) - index;
                    } else {
                      value = (_currentIndex - index).toDouble();
                    }
                    final angle = value.clamp(-1.0, 1.0) * 0.55; // gentle curl, not a full flip
                    return Transform(
                      alignment: value <= 0 ? Alignment.centerLeft : Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(angle),
                      child: child,
                    );
                  },
                  child: _buildPage(index),
                );
              },
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    final textController = _textControllers[index];
    final canvas = _controllers[index];

    if (page == null || textController == null || canvas == null) {
      // Trigger the async load; meanwhile show blank ruled paper so the
      // flip animation has something to show immediately.
      _loadPage(index);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.paperCream,
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: RuledPaperPainter())),

          // Top header: the date this page was first written on (not
          // "today" every time it's reopened — a real exercise book
          // page keeps the date the student wrote it).
          Positioned(
            top: 10,
            left: PaperLayout.marginFromLeft + 8,
            right: 12,
            child: Text(
              DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(page.updatedAt)),
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),

          if (index == 0)
            const Positioned(
              top: 28,
              left: PaperLayout.marginFromLeft + 8,
              child: Text('CONTENTS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            ),

          // Typed text layer
          Positioned(
            top: PaperLayout.topPadding,
            left: PaperLayout.marginFromLeft + 8,
            right: 12,
            bottom: 24,
            child: IgnorePointer(
              ignoring: _mode != InputMode.typing,
              child: TextField(
                controller: textController,
                maxLines: null,
                expands: true,
                onChanged: (_) => _scheduleSave(index),
                style: TextStyle(
                  fontSize: 19,
                  height: PaperLayout.lineSpacing / 19,
                  color: _color,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.4,
                ),
                decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
              ),
            ),
          ),

          // Drawing + stickers layer
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _mode != InputMode.drawing,
              child: DrawingCanvas(controller: canvas),
            ),
          ),

          if ((_pages[index]?.isBookmarked ?? false))
            Positioned(
              top: 0,
              right: 18,
              child: Container(
                width: 18,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
              ),
            ),

          // Small page number, bottom-centre of the leaf.
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),

          // Tiny, almost-invisible watermark — visible only if you look
          // closely, like a real watermark pressed into the paper.
          const Positioned(
            bottom: 4,
            right: 8,
            child: Opacity(
              opacity: 0.14,
              child: Text(AppInfo.developerCredit, style: TextStyle(fontSize: 7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final canvas = _controllers[_currentIndex];
    return Container(
      color: AppColors.coverBrown,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeButton(Icons.keyboard, InputMode.typing, 'Type'),
                  _modeButton(Icons.edit, InputMode.drawing, 'Draw'),
                  const SizedBox(width: 12),
                  ...AppColors.inkColors.map(_colorDot),
                  const SizedBox(width: 12),
                  if (_mode == InputMode.drawing) ..._toolButtons(),
                  const SizedBox(width: 12),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.undo),
                    onPressed: canvas?.canUndo == true ? canvas!.undo : null,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.redo),
                    onPressed: canvas?.canRedo == true ? canvas!.redo : null,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: _showStickerPicker,
                  ),
                ],
              ),
            ),
            if (_mode == InputMode.drawing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.line_weight, color: Colors.white70, size: 18),
                    Expanded(
                      child: Slider(
                        value: _penWidth,
                        min: 1,
                        max: 14,
                        onChanged: (v) {
                          setState(() => _penWidth = v);
                          canvas?.width = v;
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(IconData icon, InputMode mode, String label) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? Colors.black : Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white70)),
        ]),
        selected: selected,
        onSelected: (_) {
          setState(() => _mode = mode);
          if (mode == InputMode.drawing) {
            final canvas = _controllers[_currentIndex];
            if (canvas != null) {
              canvas.tool = _tool;
              canvas.color = _color;
              canvas.width = _penWidth;
            }
          }
        },
        selectedColor: AppColors.accent,
        backgroundColor: Colors.white.withOpacity(0.08),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = color.value == _color.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _onColorChanged(color),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
          ),
        ),
      ),
    );
  }

  List<Widget> _toolButtons() {
    final canvas = _controllers[_currentIndex];
    final tools = [
      (DrawTool.pen, Icons.edit, 'Pen'),
      (DrawTool.pencil, Icons.create_outlined, 'Pencil'),
      (DrawTool.marker, Icons.brush, 'Marker'),
      (DrawTool.highlighter, Icons.border_color, 'Highlighter'),
      (DrawTool.eraser, Icons.auto_fix_normal, 'Eraser'),
      (DrawTool.line, Icons.show_chart, 'Line'),
      (DrawTool.circle, Icons.circle_outlined, 'Circle'),
      (DrawTool.rectangle, Icons.crop_square, 'Rectangle'),
      (DrawTool.triangle, Icons.change_history, 'Triangle'),
      (DrawTool.arrow, Icons.north_east, 'Arrow'),
    ];
    return tools.map((t) {
      final selected = _tool == t.$1;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton(
          tooltip: t.$3,
          icon: Icon(t.$2, color: selected ? AppColors.accent : Colors.white70),
          onPressed: () {
            setState(() => _tool = t.$1);
            if (canvas != null) {
              canvas.tool = t.$1;
              canvas.color = _color;
              canvas.width = _penWidth;
            }
          },
        ),
      );
    }).toList();
  }

  void _showStickerPicker() {
    const stickers = ['⭐', '✔', '⚠', '😊', '❤', '❓'];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: stickers
              .map((emoji) => ListTile(
                    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                    title: Text('Place $emoji'),
                    onTap: () {
                      _controllers[_currentIndex]?.pendingStickerEmoji = emoji;
                      Navigator.pop(context);
                      setState(() => _mode = InputMode.drawing);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
