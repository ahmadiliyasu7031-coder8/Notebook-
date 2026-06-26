import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../database/notebook_repository.dart';
import '../database/page_repository.dart';
import '../database/settings_repository.dart';
import '../models/notebook.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) => NotebookRepository());
final pageRepositoryProvider = Provider<PageRepository>((ref) => PageRepository());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

final notebooksProvider = AsyncNotifierProvider<NotebooksNotifier, List<Notebook>>(
  NotebooksNotifier.new,
);

class NotebooksNotifier extends AsyncNotifier<List<Notebook>> {
  @override
  Future<List<Notebook>> build() async {
    final repo = ref.read(notebookRepositoryProvider);
    return repo.getAll();
  }

  Future<void> updateNotebook(Notebook notebook) async {
    final repo = ref.read(notebookRepositoryProvider);
    await repo.update(notebook);
    ref.invalidateSelf();
    await future;
  }

  Future<void> markOpened(String notebookId) async {
    final repo = ref.read(notebookRepositoryProvider);
    final nb = await repo.getById(notebookId);
    if (nb == null) return;
    await repo.update(nb.copyWith(lastOpenedAt: DateTime.now().millisecondsSinceEpoch));
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    final raw = await repo.getThemeMode();
    return AppThemeMode.values.firstWhere((m) => m.name == raw, orElse: () => AppThemeMode.light);
  }

  Future<void> setMode(AppThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setThemeMode(mode.name);
    state = AsyncData(mode);
  }
}
