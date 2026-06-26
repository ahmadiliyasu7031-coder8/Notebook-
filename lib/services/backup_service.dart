import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Backs up / restores the entire app by copying the single SQLite
/// database file that holds every notebook and page. Simple, robust,
/// and fully offline — no special backup file format to maintain.
class BackupService {
  static Future<String> _dbPath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, 'pocket_exercise_book.db');
  }

  static Future<void> backupAndShare() async {
    // Make sure everything pending is flushed before copying the file.
    await DatabaseHelper.instance.database;

    final dbFile = File(await _dbPath());
    if (!await dbFile.exists()) return;

    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File(
      p.join(tempDir.path, 'pocket_exercise_book_backup_$stamp.peb'),
    );

    await dbFile.copy(backupFile.path);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Pocket Exercise Book backup',
        files: [XFile(backupFile.path)],
      ),
    );
  }

  /// Returns true on success. The caller should prompt the user to
  /// restart the app afterward, since the database connection already
  /// in memory needs to be reopened against the restored file.
  static Future<bool> restoreFromPickedFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return false;

    final pickedPath = result.files.first.path;
    if (pickedPath == null) return false;

    final picked = File(pickedPath);
    if (!await picked.exists()) return false;

    await DatabaseHelper.instance.close();

    final targetPath = await _dbPath();
    await picked.copy(targetPath);

    return true;
  }
}
