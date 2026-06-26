import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../database/page_repository.dart';
import '../models/notebook_page.dart';
import '../providers/notebook_providers.dart';
import 'notebook_page_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _pageRepo = PageRepository();
  final _controller = TextEditingController();
  List<NotebookPage> _results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _pageRepo.searchAll(query.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  String _highlightSnippet(String text, String query) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return text.length > 80 ? '${text.substring(0, 80)}…' : text;
    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + query.length + 30).clamp(0, text.length);
    return '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final notebooksAsync = ref.watch(notebooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _search,
          decoration: const InputDecoration(
            hintText: 'Search all notebooks…',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : notebooksAsync.when(
              data: (notebooks) {
                if (_results.isEmpty) {
                  return Center(
                    child: Text(
                      _controller.text.isEmpty ? 'Type to search' : 'No matches found',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final page = _results[index];
                    final notebook = notebooks.firstWhere(
                      (n) => n.id == page.notebookId,
                      orElse: () => notebooks.first,
                    );
                    return ListTile(
                      title: Text(
                          '${notebook.name.isEmpty ? 'Untitled' : notebook.name} — Page ${page.pageIndex + 1}'),
                      subtitle: Text(_highlightSnippet(page.plainText, _controller.text)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => NotebookPageScreen(notebook: notebook)),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }
}
