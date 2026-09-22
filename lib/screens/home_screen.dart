import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/homa_ir_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final latest = provider.latest;
    final hasResult = latest != null && latest.homaIr != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Shif', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
            Text('AI', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                child: hasResult
                    ? _statusView(latest)
                    : _welcomeView(context),
              ),
      ),
    );
  }

  /// First-run state — one warm message, one clear next step. No menu of
  /// competing options, matching the "Welcome to Wanis / Start Setup" pattern.
  Widget _welcomeView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.pastel,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, color: AppColors.gold, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to ShifAI',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          const Text(
            'A quiet companion for your metabolic health —\ncatching risk early, long before it becomes a diagnosis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, height: 1.4),
          ),
          const SizedBox(height: 28),
          const Text(
            'Tap + to add your first result, from a photo\nof a lab report or by typing it in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Returning state — the number, a plain-language status line in a
  /// contextual banner (green/amber/red), nothing else competing for attention.
  Widget _statusView(LabRecord latest) {
    final band = latest.homaIrBand!;
    final banner = _bannerFor(band);

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('Your latest HOMA-IR', style: TextStyle(color: AppColors.gray)),
        const SizedBox(height: 16),
        HomaIrBadge(homaIr: latest.homaIr!, band: band, size: 120),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: banner.bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(banner.icon, color: banner.fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  banner.message,
                  style: TextStyle(color: banner.fg, fontSize: 13.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.creamCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.pastelBorder),
          ),
          child: const Text(
            'ShifAI is a risk-awareness tool, not a diagnosis. Always confirm '
            'results with your doctor.',
            style: TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ),
      ],
    );
  }

  _Banner _bannerFor(HomaIrBand band) {
    switch (band) {
      case HomaIrBand.optimal:
      case HomaIrBand.normal:
        return _Banner(
          bg: AppColors.safeBg,
          fg: AppColors.safeText,
          icon: Icons.check_circle_outline,
          message: "You're in a healthy range. Keep up your current habits — "
              'add a new result any time to keep tracking your trend.',
        );
      case HomaIrBand.earlyResistance:
        return _Banner(
          bg: AppColors.warningBg,
          fg: AppColors.warningText,
          icon: Icons.info_outline,
          message: 'This suggests early insulin resistance. A short walk after '
              'meals and cutting back on refined carbs can help — and it\'s '
              'worth mentioning to your doctor.',
        );
      case HomaIrBand.significantResistance:
        return _Banner(
          bg: AppColors.dangerBg,
          fg: AppColors.dangerText,
          icon: Icons.warning_amber_outlined,
          message: 'This is in a range worth discussing with your doctor soon. '
              "ShifAI can't diagnose you, but this pattern is one they should know about.",
        );
    }
  }
}

class _Banner {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String message;
  _Banner({required this.bg, required this.fg, required this.icon, required this.message});
}
