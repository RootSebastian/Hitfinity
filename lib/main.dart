import 'package:flutter/material.dart';
import 'database/database_provider.dart';
import 'screens/shell_screen.dart';
import 'services/hit_settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HitSettings.I.load();

  await DatabaseProvider.instance.customSelect('SELECT 1').get();

  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HitSettings.I.listenable,
      builder: (context, _) {
        final s = HitSettings.I;
        return MaterialApp(
          title: 'Hitfinity',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(amoled: s.amoled.value),
          themeMode: s.mode.value,
          home: const ShellScreen(),
        );
      },
    );
  }
}
