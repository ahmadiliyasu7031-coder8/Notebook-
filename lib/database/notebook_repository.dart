import 'package:sqflite/sqflite.dart';

import '../models/notebook.dart';
import 'database_helper.dart';

class NotebookRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<List<Notebook>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('notebooks', orderBy: 'slot_index ASC');
    return rows.map((r) => Notebook.fromMap(r)).toList();
  }

  Future<Notebook?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('notebooks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Notebook.fromMap(rows.first);
  }

  Future<void> update(Notebook notebook) async {
    final db = await _dbHelper.database;
    await db.update('notebooks', notebook.toMap(), where: 'id = ?', whereArgs: [notebook.id]);
  }

  Future<List<Notebook>> getRecent({int limit = 5}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notebooks',
      where: 'last_opened_at > 0',
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return rows.map((r) => Notebook.fromMap(r)).toList();
  }

  Future<List<Notebook>> getFavorites() async {
    final db = await _dbHelper.database;
    final rows = await db.query('notebooks', where: 'is_favorite = 1', orderBy: 'slot_index ASC');
    return rows.map((r) => Notebook.fromMap(r)).toList();
  }

  Future<List<Notebook>> search(String query) async {
    final db = await _dbHelper.database;
    final like = '%$query%';
    final rows = await db.query(
      'notebooks',
      where: 'name LIKE ? OR subject LIKE ? OR school LIKE ? OR reg_no LIKE ?',
      whereArgs: [like, like, like, like],
      orderBy: 'slot_index ASC',
    );
    return rows.map((r) => Notebook.fromMap(r)).toList();
  }
}
