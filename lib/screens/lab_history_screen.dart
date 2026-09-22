import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/homa_ir_badge.dart';

class LabHistoryScreen extends StatelessWidget {
  const LabHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final records = provider.records.where((r) => r.homaIr != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('HOMA-IR trend')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : records.length < 2
              ? _emptyState(records.length)
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SizedBox(height: 220, child: _TrendChart(records: records)),
                    const SizedBox(height: 24),
                    const Text('All results',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...provider.records.reversed.map((r) => _RecordTile(record: r)),
                  ],
                ),
    );
  }

  Widget _emptyState(int count) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart, size: 48, color: AppColors.accentBlue),
            const SizedBox(height: 12),
            Text(
              count == 0
                  ? 'No lab results yet. Add your first one to start tracking your HOMA-IR trend.'
                  : 'Add one more result with both glucose and insulin to see your trend line.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<LabRecord> records;
  const _TrendChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < records.length; i++) FlSpot(i.toDouble(), records[i].homaIr!),
    ];
    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3)
        .clamp(2.0, 100.0);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).clamp(0.5, 100),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.pastelBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (maxY / 4).clamp(0.5, 100),
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                  style: const TextStyle(color: AppColors.gray, fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= records.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat.Md().format(records[i].date),
                      style: const TextStyle(color: AppColors.gray, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.navy,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) =>
                  FlDotCirclePainter(radius: 4, color: AppColors.accentBlue, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(show: true, color: AppColors.pastel.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final LabRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (record.homaIr != null && record.homaIrBand != null)
              HomaIrBadge(homaIr: record.homaIr!, band: record.homaIrBand!, size: 56)
            else
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.pastel,
                child: Icon(Icons.science_outlined, color: AppColors.navy),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat.yMMMd().format(record.date),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (record.fastingGlucoseMgdl != null)
                    Text('Glucose: ${record.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                  if (record.fastingInsulinUiuml != null)
                    Text('Insulin: ${record.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                  if (record.hba1cPercent != null)
                    Text('HbA1c: ${record.hba1cPercent!.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
