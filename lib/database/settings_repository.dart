import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class SettingsRepository {
  final _dbHelper = DatabaseHelper.instance;
  static const keyThemeMode = 'theme_mode';

  Future<String?> _get(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _set(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert('app_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getThemeMode() async => (await _get(keyThemeMode)) ?? 'light';
  Future<void> setThemeMode(String mode) => _set(keyThemeMode, mode);
}
