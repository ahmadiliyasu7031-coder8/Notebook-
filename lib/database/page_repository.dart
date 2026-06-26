import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/notebook_page.dart';
import 'database_helper.dart';

class PageRepository {
  final _dbHelper = DatabaseHelper.instance;

  /// Returns the page at [pageIndex] for a notebook, creating a blank
  /// one on first access. Pages are lazily materialized — a freshly
  /// created notebook has no rows yet, only the promise of 60 leaves.
  Future<NotebookPage> getOrCreate(String notebookId, int pageIndex) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pages',
      where: 'notebook_id = ? AND page_index = ?',
      whereArgs: [notebookId, pageIndex],
      limit: 1,
    );
    if (rows.isNotEmpty) return NotebookPage.fromMap(rows.first);

    final blank = NotebookPage(
      id: '$notebookId-p$pageIndex',
      notebookId: notebookId,
      pageIndex: pageIndex,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return blank; // not persisted until the user actually writes something
  }

  Future<void> save(NotebookPage page) async {
    final db = await _dbHelper.database;
    await db.insert('pages', page.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NotebookPage>> getAllForNotebook(String notebookId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pages',
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
      orderBy: 'page_index ASC',
    );
    return rows.map((r) => NotebookPage.fromMap(r)).toList();
  }

  Future<List<NotebookPage>> getBookmarked(String notebookId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pages',
      where: 'notebook_id = ? AND is_bookmarked = 1',
      whereArgs: [notebookId],
      orderBy: 'page_index ASC',
    );
    return rows.map((r) => NotebookPage.fromMap(r)).toList();
  }

  Future<int> countUsedLeaves(String notebookId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('pages', where: 'notebook_id = ?', whereArgs: [notebookId]);
    final pages = rows.map((r) => NotebookPage.fromMap(r)).where((p) => !p.isBlank);
    return pages.length;
  }

  int get totalLeaves => PaperLayout.totalLeaves;

  /// Search page text within one notebook.
  Future<List<NotebookPage>> searchInNotebook(String notebookId, String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pages',
      where: 'notebook_id = ? AND text_runs LIKE ?',
      whereArgs: [notebookId, '%$query%'],
      orderBy: 'page_index ASC',
    );
    return rows.map((r) => NotebookPage.fromMap(r)).toList();
  }

  /// Search page text across every notebook.
  Future<List<NotebookPage>> searchAll(String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pages',
      where: 'text_runs LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'notebook_id ASC, page_index ASC',
    );
    return rows.map((r) => NotebookPage.fromMap(r)).toList();
  }
}
