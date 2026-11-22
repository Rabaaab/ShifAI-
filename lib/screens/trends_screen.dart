import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../providers/profile_provider.dart';
import '../services/risk_model.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../utils/share_summary.dart';
import '../widgets/band_style.dart';
import '../widgets/ds_widgets.dart';

enum TrendMetric { homaIr, glucose, hba1c, insulin }

extension TrendMetricX on TrendMetric {
  String get tab {
    switch (this) {
      case TrendMetric.homaIr:
        return 'HOMA-IR';
      case TrendMetric.glucose:
        return 'Glucose'.tr;
      case TrendMetric.hba1c:
        return 'HbA1c';
      case TrendMetric.insulin:
        return 'Insulin'.tr;
    }
  }

  String get title {
    switch (this) {
      case TrendMetric.homaIr:
        return 'HOMA-IR';
      case TrendMetric.glucose:
        return 'fasting glucose'.tr;
      case TrendMetric.hba1c:
        return 'HbA1c';
      case TrendMetric.insulin:
        return 'fasting insulin'.tr;
    }
  }

  String get unit {
    switch (this) {
      case TrendMetric.homaIr:
        return 'index';
      case TrendMetric.glucose:
        return 'mg/dL';
      case TrendMetric.hba1c:
        return '%';
      case TrendMetric.insulin:
        return 'µIU/mL';
    }
  }

  int get decimals =>
      this == TrendMetric.glucose ? 0 : (this == TrendMetric.homaIr ? 2 : 1);

  double? valueOf(LabRecord r) {
    switch (this) {
      case TrendMetric.homaIr:
        return r.homaIr;
      case TrendMetric.glucose:
        return r.fastingGlucoseMgdl;
      case TrendMetric.hba1c:
        return r.hba1cPercent;
      case TrendMetric.insulin:
        return r.fastingInsulinUiuml;
    }
  }
}

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendMetric _metric = TrendMetric.homaIr;

  Future<void> _confirmDelete(LabRecord record) async {
    final provider = context.read<LabRecordsProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete this result?'.tr,
          style: DS.text(weight: FontWeight.w800),
        ),
        content: Text(
          'It will be removed from your history and synced to your account '
                  'when online.'
              .tr,
          style: DS.text(size: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'.tr, style: TextStyle(color: DS.redText)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deleteRecord(record.id);
  }

  void _openDetails(LabRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DS.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().format(record.date),
              style: DS.text(size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (record.homaIr != null)
              Row(
                children: [
                  Text(
                    record.homaIr!.toStringAsFixed(2),
                    style: DS.text(size: 34, weight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  BandChip(band: record.homaIrBand!),
                ],
              ),
            const SizedBox(height: 12),
            if (record.fastingGlucoseMgdl != null)
              _detail(
                'Fasting glucose'.tr,
                '${record.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
              ),
            if (record.fastingInsulinUiuml != null)
              _detail(
                'Fasting insulin'.tr,
                '${record.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL',
              ),
            if (record.hba1cPercent != null)
              _detail('HbA1c', '${record.hba1cPercent!.toStringAsFixed(1)} %'),
            const SizedBox(height: 18),
            DsOutlineButton(
              label: 'Delete this result'.tr,
              color: DS.redText,
              iconColor: DS.redText,
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDelete(record);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DS.text(size: 15, weight: FontWeight.w500, color: DS.muted),
        ),
        Text(value, style: DS.text(size: 15.5, weight: FontWeight.w700)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabRecordsProvider>();
    final all = provider.records;
    final withHoma = all.where((r) => r.homaIr != null).toList();
    final series = all.where((r) => _metric.valueOf(r) != null).toList();

    return DsBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            const DsTitle('Your', 'trends', size: 38),
            const SizedBox(height: 22),
            if (all.isEmpty)
              const _EmptyTrends()
            else ...[
              if (withHoma.isNotEmpty)
                _ScoreCard(first: withHoma.first, latest: withHoma.last)
              else
                _NoHomaCard(latest: all.last),
              const SizedBox(height: 20),
              _MetricTabs(
                selected: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: 20),
              _ChartCard(metric: _metric, series: series),
              const SizedBox(height: 24),
              Text(
                'Results'.tr,
                style: DS.text(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final r in all.reversed) ...[
                _ResultRow(record: r, onTap: () => _openDetails(r)),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DsPrimaryButton(
                      label: 'Add result'.tr,
                      icon: Icons.add_rounded,
                      height: 58,
                      onPressed: () => openAddResult(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DsOutlineButton(
                      label: 'Share'.tr,
                      icon: Icons.share_outlined,
                      onPressed: () =>
                          shareSummaryOnWhatsApp(context, all.last),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyTrends extends StatelessWidget {
  const _EmptyTrends();

  @override
  Widget build(BuildContext context) => DsCard(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const DsIconBadge(icon: Icons.show_chart_rounded, size: 56),
        const SizedBox(height: 16),
        Text(
          'No results yet'.tr,
          style: DS.text(size: 20, weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Scan a lab report to see your score and your trend.'.tr,
          textAlign: TextAlign.center,
          style: DS.text(
            size: 14.5,
            weight: FontWeight.w500,
            color: DS.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        DsPrimaryButton(
          label: 'Scan a report'.tr,
          icon: Icons.document_scanner_outlined,
          height: 56,
          onPressed: () => openAddResult(context),
        ),
      ],
    ),
  );
}

/// No HOMA-IR yet (no insulin value). When the latest result has glucose,
/// HbA1c, triglycerides and HDL and the body measurements are known, show the
/// estimate that needs no insulin test; otherwise say what is missing.
class _NoHomaCard extends StatelessWidget {
  const _NoHomaCard({required this.latest});
  final LabRecord latest;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;
    final model = provider.model;
    final hasLabs =
        latest.fastingGlucoseMgdl != null &&
        latest.hba1cPercent != null &&
        latest.triglyceridesMgdl != null &&
        latest.hdlMgdl != null;

    if (hasLabs && profile != null && model != null) {
      final a = model.assessLabs(
        profile,
        LabInputs(
          glucoseMgdl: latest.fastingGlucoseMgdl!,
          hba1cPercent: latest.hba1cPercent!,
          triglyceridesMgdl: latest.triglyceridesMgdl!,
          hdlMgdl: latest.hdlMgdl!,
        ),
      );
      final (bg, fg) = switch (a.band) {
        RiskBand.low => (DS.greenTint, DS.greenText),
        RiskBand.moderate => (DS.amberTint, DS.amberText),
        RiskBand.high => (DS.redTint, DS.redText),
      };
      final reasons = a.topFactors(max: 3);
      return DsCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimate without insulin'.tr,
                  style: DS.text(
                    size: 15,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
                DsPill(a.band.label, background: bg, foreground: fg),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${a.percent}%',
              style: DS.text(
                size: 56,
                weight: FontWeight.w800,
                letterSpacing: -2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reasons.isEmpty
                  ? 'Chance that your HOMA-IR is 2.5 or higher.'.tr
                  : 'Chance that your HOMA-IR is 2.5 or higher. Mainly because '
                            'of: {v}.'
                        .trf({
                          'v': reasons
                              .map((f) => f.label.toLowerCase())
                              .join(', '),
                        }),
              style: DS.text(
                size: 14,
                weight: FontWeight.w500,
                color: DS.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return DsCard(
      padding: const EdgeInsets.all(22),
      child: Text(
        hasLabs
            ? 'Add your age, sex, height, weight and waist in your profile to '
                      'get an estimate from these blood values.'
                  .tr
            : 'Add both fasting glucose and insulin to see your HOMA-IR score. '
                      'Without insulin, glucose, HbA1c, triglycerides and HDL '
                      'together give an estimate.'
                  .tr,
        style: DS.text(
          size: 15,
          weight: FontWeight.w500,
          color: DS.muted,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.first, required this.latest});
  final LabRecord first;
  final LabRecord latest;

  static const _max = 4.5;

  @override
  Widget build(BuildContext context) {
    final value = latest.homaIr!;
    final band = latest.homaIrBand!;
    final change = identical(first, latest) ? null : value - first.homaIr!;
    final lower = change != null && change < 0;

    return DsCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOMA-IR',
                style: DS.text(
                  size: 15,
                  weight: FontWeight.w600,
                  color: DS.muted,
                ),
              ),
              BandChip(band: band),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(2),
                style: DS.text(
                  size: 60,
                  weight: FontWeight.w800,
                  letterSpacing: -2.4,
                  height: 1.05,
                ),
              ),
              const Spacer(),
              if (change != null && change.abs() >= 0.005)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        lower
                            ? Icons.south_east_rounded
                            : Icons.north_east_rounded,
                        size: 17,
                        color: lower ? DS.greenText : DS.amberText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '{v} since '
                                '{v2}'
                            .trf({
                              'v': change.abs().toStringAsFixed(2),
                              'v2': DateFormat.MMM().format(first.date),
                            }),
                        style: DS.text(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: lower ? DS.greenText : DS.amberText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final dotX = (value / _max).clamp(0.0, 1.0) * c.maxWidth;
              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          for (final seg in const [
                            (100, Color(0xFFBFE6D3)),
                            (90, Color(0xFFD4EEE0)),
                            (60, Color(0xFFFFE2A6)),
                            (200, Color(0xFFF7C3C9)),
                          ]) ...[
                            Expanded(
                              flex: seg.$1,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: seg.$2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            if (seg.$1 != 200) const SizedBox(width: 3),
                          ],
                        ],
                      ),
                      Positioned(
                        left: math.max(0, dotX - 10),
                        top: -5,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: DS.navy,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: DS.navy.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 18,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: Text(
                            '0',
                            style: DS.text(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: DS.iconMuted,
                            ),
                          ),
                        ),
                        for (final mark in const [
                          ('1.0', 1.0),
                          ('1.9', 1.9),
                          ('2.5', 2.5),
                        ])
                          Positioned(
                            left: (mark.$2 / _max) * c.maxWidth - 10,
                            child: Text(
                              mark.$1,
                              style: DS.text(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: DS.iconMuted,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          child: Text(
                            '4.5+',
                            style: DS.text(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: DS.iconMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricTabs extends StatelessWidget {
  const _MetricTabs({required this.selected, required this.onChanged});
  final TrendMetric selected;
  final ValueChanged<TrendMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in TrendMetric.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: m == selected,
              label: m.tab,
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == selected
                        ? Colors.white
                        : DS.navy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: m == selected
                        ? [
                            BoxShadow(
                              color: DS.navy.withValues(alpha: 0.10),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      m.tab,
                      style: DS.text(
                        size: 14,
                        weight: m == selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: m == selected ? DS.navy : DS.iconMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (m != TrendMetric.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.metric, required this.series});
  final TrendMetric metric;
  final List<LabRecord> series;

  @override
  Widget build(BuildContext context) {
    final values = series.map((r) => metric.valueOf(r)!).toList();
    final n = values.length;

    double? pct;
    if (n >= 2 && values.first != 0) {
      pct = (values.last - values.first) / values.first * 100;
    }

    return DsCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Over time'.tr,
                style: DS.text(size: 18, weight: FontWeight.w700),
              ),
              if (pct != null && pct.abs() >= 0.5)
                DsPill(
                  '${pct < 0 ? 'Down' : 'Up'} ${pct.abs().toStringAsFixed(0)}%',
                  background: pct < 0 ? DS.greenTint : DS.amberTint,
                  foreground: pct < 0 ? DS.greenText : DS.amberText,
                  vertical: 6,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            n == 1 ? '1 lab checkup'.tr : '{n} lab checkups'.trf({'n': n}),
            style: DS.text(size: 14, weight: FontWeight.w500, color: DS.muted),
          ),
          const SizedBox(height: 14),
          if (n == 0)
            Text(
              'No results with this value yet.'.tr,
              style: DS.text(color: DS.muted),
            )
          else if (n < 2)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DS.field,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Add one more result with this value to see your trend line.'
                    .tr,
                style: DS.text(size: 14.5, color: DS.muted, height: 1.4),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: _TrendChart(metric: metric, series: series),
            ),
            if (metric == TrendMetric.homaIr) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFE6D3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Healthy zone'.tr,
                    style: DS.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: DS.muted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.metric, required this.series});
  final TrendMetric metric;
  final List<LabRecord> series;

  @override
  Widget build(BuildContext context) {
    final values = series.map((r) => metric.valueOf(r)!).toList();
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, hi.abs() * 0.05 + 0.1);

    final isHoma = metric == TrendMetric.homaIr;
    final minY = isHoma ? 0.0 : math.max(0.0, lo - pad);
    final maxY = isHoma ? math.max(hi + pad, 2.6) : hi + pad;
    final yInterval = math.max((maxY - minY) / 4, 0.1);
    final xInterval = math.max(1, (series.length / 5).ceil()).toDouble();
    const gridColor = Color(0xFFE6EDF5);
    final axis = DS.text(
      size: 11.5,
      weight: FontWeight.w600,
      color: DS.iconMuted,
    );

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (isHoma)
              HorizontalRangeAnnotation(
                y1: 0,
                y2: 1.9,
                color: const Color(0xFFBFE6D3).withValues(alpha: 0.6),
              ),
          ],
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(metric.decimals == 0 ? 0 : 1),
                style: axis,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (v != i || i < 0 || i >= series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.MMM().format(series[i].date),
                    style: axis,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            color: DS.navy,
            barWidth: 3.5,
            belowBarData: BarAreaData(
              show: true,
              color: DS.navy.withValues(alpha: 0.07),
            ),
            dotData: FlDotData(
              getDotPainter: (spot, _, bar, index) {
                final last = index == values.length - 1;
                return FlDotCirclePainter(
                  radius: last ? 7 : 4.5,
                  color: last ? DS.navy : Colors.white,
                  strokeColor: last ? Colors.white : DS.navy,
                  strokeWidth: 3,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= series.length) return null;
              return LineTooltipItem(
                '${DateFormat.MMMd().format(series[index].date)}\n'
                '${spot.y.toStringAsFixed(metric.decimals)} ${metric.unit}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.record, required this.onTap});
  final LabRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final band = record.homaIrBand;
    final parts = <String>[
      if (record.fastingGlucoseMgdl != null)
        '${record.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
      if (record.fastingInsulinUiuml != null)
        '${record.fastingInsulinUiuml!.toStringAsFixed(1)} uIU/mL',
      if (record.hba1cPercent != null)
        'HbA1c ${record.hba1cPercent!.toStringAsFixed(1)}%',
    ];
    return Semantics(
      button: true,
      label: 'Result of {v}'.trf({'v': DateFormat.MMMd().format(record.date)}),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: DS.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: band == null ? DS.field : bandBackground(band),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  record.homaIr == null
                      ? '--'
                      : record.homaIr!.toStringAsFixed(2),
                  style: DS.text(
                    size: 16,
                    weight: FontWeight.w800,
                    color: band == null ? DS.muted : bandTextColor(band),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.MMMd().format(record.date),
                      style: DS.text(size: 15.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parts.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DS.text(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: DS.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: DS.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
