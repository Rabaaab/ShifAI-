import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/homa_ir_badge.dart';
import 'lab_entry_form_screen.dart';
import 'lab_history_screen.dart';
import 'lab_scan_screen.dart';

/// Camera-based OCR relies on Google ML Kit, which only ships Android/iOS
/// implementations. On other platforms we hide the scan option and go
/// straight to manual entry instead of letting it crash at runtime.
bool get _scanSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final latest = provider.latest;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text('Shif', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
            Text('AI', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: provider.loading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ))
                    : latest == null || latest.homaIr == null
                        ? _noDataYet(context)
                        : _latestResult(context, latest.homaIr!, latest.homaIrBand!,
                            latest.date),
              ),
            ),
            const SizedBox(height: 20),
            _ActionCard(
              icon: _scanSupported ? Icons.document_scanner_outlined : Icons.edit_note,
              title: _scanSupported ? 'Scan a lab report' : 'Add a lab result',
              subtitle: _scanSupported
                  ? 'Photograph a printed report — glucose, insulin, HbA1c'
                  : 'Enter glucose, insulin or HbA1c manually',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _scanSupported
                    ? const LabScanScreen()
                    : const LabEntryFormScreen(),
              )),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.show_chart,
              title: 'View trend',
              subtitle: 'HOMA-IR history over time',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LabHistoryScreen()),
              ),
            ),
            if (_scanSupported) ...[
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.edit_note,
                title: 'Enter values manually',
                subtitle: 'No photo needed',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LabEntryFormScreen()),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pastel.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ShifAI is a risk-awareness and early-screening tool, not a '
                'diagnosis. Always confirm results with your doctor.',
                style: TextStyle(color: AppColors.navy, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noDataYet(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.science_outlined, size: 40, color: AppColors.accentBlue),
        SizedBox(height: 10),
        Text('No results yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 6),
        Text(
          'Add your fasting glucose and insulin to see your HOMA-IR score.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.gray),
        ),
      ],
    );
  }

  Widget _latestResult(
      BuildContext context, double homaIr, dynamic band, DateTime date) {
    return Column(
      children: [
        const Text('Latest HOMA-IR', style: TextStyle(color: AppColors.gray)),
        const SizedBox(height: 12),
        HomaIrBadge(homaIr: homaIr, band: band, size: 110),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.pastel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gray),
            ],
          ),
        ),
      ),
    );
  }
}
