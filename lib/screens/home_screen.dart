import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/notebook.dart';
import '../providers/notebook_providers.dart';
import '../widgets/notebook_cover.dart';
import 'notebook_edit_sheet.dart';
import 'notebook_page_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  Future<void> _openNotebook(Notebook notebook) async {
    if (notebook.isEmpty) {
      final updated = await showModalBottomSheet<Notebook>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NotebookEditSheet(notebook: notebook),
      );
      if (updated == null) return;
      await ref.read(notebooksProvider.notifier).updateNotebook(updated);
      if (!mounted) return;
    }

    await ref.read(notebooksProvider.notifier).markOpened(notebook.id);
    if (!mounted) return;
    final fresh = (await ref.read(notebooksProvider.future)).firstWhere((n) => n.id == notebook.id);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => NotebookPageScreen(notebook: fresh),
        transitionsBuilder: (_, animation, __, child) {
          final scale = Tween<double>(begin: 0.85, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  Future<void> _editNotebook(Notebook notebook) async {
    final updated = await showModalBottomSheet<Notebook>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotebookEditSheet(notebook: notebook),
    );
    if (updated != null) {
      await ref.read(notebooksProvider.notifier).updateNotebook(updated);
    }
  }

  Future<void> _toggleFavorite(Notebook notebook) async {
    await ref.read(notebooksProvider.notifier).updateNotebook(
          notebook.copyWith(isFavorite: !notebook.isFavorite),
        );
  }

  Future<void> _openWhatsAppGroup() async {
    final uri = Uri.parse(
      'https://wa.me/2347083324469?text=${Uri.encodeComponent('Hello I want to join the Pocket Exercise Book developers group.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final notebooksAsync = ref.watch(notebooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pocket Exercise Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Your School Bag In Your Pocket', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: notebooksAsync.when(
        data: (notebooks) {
          final filtered = _query.isEmpty
              ? notebooks
              : notebooks
                  .where((n) =>
                      n.name.toLowerCase().contains(_query.toLowerCase()) ||
                      n.subject.toLowerCase().contains(_query.toLowerCase()) ||
                      n.school.toLowerCase().contains(_query.toLowerCase()))
                  .toList();
          final recents = notebooks.where((n) => n.lastOpenedAt > 0).toList()
            ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search notebooks…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              if (recents.isNotEmpty && _query.isEmpty) ...[
                const SizedBox(height: 20),
                const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recents.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final n = recents[i];
                      return ActionChip(
                        label: Text(n.name.isEmpty ? 'Untitled' : n.name),
                        onPressed: () => _openNotebook(n),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Your School Bag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  final notebook = filtered[index];
                  return GestureDetector(
                    onLongPress: () => _editNotebook(notebook),
                    child: NotebookCover(
                      notebook: notebook,
                      onTap: () => _openNotebook(notebook),
                      onToggleFavorite: () => _toggleFavorite(notebook),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Text('Created by Ahmad Iliyasu Babura',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Text('Student of Federal University of Technology Babura',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Contact: +2347083324469',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openWhatsAppGroup,
                      child: const Text(
                        'Join our WhatsApp group for developers',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load notebooks: $e')),
      ),
    );
  }
}
