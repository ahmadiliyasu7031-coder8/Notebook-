import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../providers/notebook_providers.dart';
import '../services/backup_service.dart';
import 'global_search_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _restore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This replaces all current notebooks with the ones in the backup file you pick. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await BackupService.restoreFromPickedFile();
    if (!context.mounted) return;
    if (success) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Restore Complete'),
          content: const Text('Please close and reopen the app for the restored notebooks to appear.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore failed or cancelled')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Across All Notebooks'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          themeModeAsync.when(
            data: (mode) => Column(
              children: AppThemeMode.values.map((m) {
                return RadioListTile<AppThemeMode>(
                  value: m,
                  groupValue: mode,
                  title: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                  onChanged: (v) {
                    if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
                  },
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox.shrink(),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup All Notebooks'),
            subtitle: const Text('Save everything to a single file you can share or store'),
            onTap: () => BackupService.backupAndShare(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore From Backup'),
            subtitle: const Text('Replace current notebooks with a backup file'),
            onTap: () => _restore(context),
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Center(
            child: Column(
              children: [
                Text('Created by Ahmad Iliyasu Babura', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Student of Federal University of Technology Babura',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
