import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/platform_helper.dart';
import 'home_screen.dart';
import 'lab_entry_form_screen.dart';
import 'lab_history_screen.dart';
import 'lab_scan_screen.dart';

/// Simple two-tab shell (Home / Trend) with one clear floating action for
/// adding a result — mirrors WanisAI's pattern of a short, labeled nav and
/// a single obvious next step, rather than a menu of competing options.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _addResult() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => isMobilePlatform ? const LabScanScreen() : const LabEntryFormScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), LabHistoryScreen()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addResult,
        backgroundColor: AppColors.buttonBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Trend'),
        ],
      ),
    );
  }
}
