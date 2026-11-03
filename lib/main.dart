import 'package:flutter/material.dart';
import 'database/database_provider.dart';
import 'screens/shell_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter is ready before touching the database
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database — triggers seeding on first run
  await DatabaseProvider.instance
      .customSelect('SELECT 1')
      .get();

  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hitfinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const ShellScreen(),
    );
  }
}