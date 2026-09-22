import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lab_records_provider.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ShifAiApp());
}

class ShifAiApp extends StatelessWidget {
  const ShifAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LabRecordsProvider()),
      ],
      child: MaterialApp(
        title: 'ShifAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}
