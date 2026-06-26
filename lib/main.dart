import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'database/database_helper.dart';
import 'providers/notebook_providers.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const ProviderScope(child: PocketExerciseBookApp()));
}

class PocketExerciseBookApp extends ConsumerWidget {
  const PocketExerciseBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);

    return themeModeAsync.when(
      data: (mode) => MaterialApp(
        title: 'Pocket Exercise Book',
        debugShowCheckedModeBanner: false,
        theme: switch (mode) {
          AppThemeMode.light => AppTheme.light,
          AppThemeMode.dark => AppTheme.dark,
          AppThemeMode.sepia => AppTheme.sepia,
        },
        home: const HomeScreen(),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
