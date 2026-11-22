import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/doctor.dart';
import '../models/lab_record.dart';
import '../models/wellness_content.dart';
import '../providers/lab_records_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../widgets/ds_widgets.dart';
import 'emergency_screen.dart';
import 'find_doctor_screen.dart';
import 'medicine_screen.dart';
import 'profile_form_screen.dart';
import 'skin_check_screen.dart';
import 'wellness_screen.dart';

class _Hit {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Hit(this.icon, this.title, this.subtitle, this.onTap);
}

/// Searches the app: features, lab results, medicine, doctors and food.
/// Everything is matched on this device.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _tab(int tab) {
    context.read<NavProvider>().setTab(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  bool _match(String q, Iterable<String> haystack) {
    return haystack.any((h) => h.toLowerCase().contains(q));
  }

  List<_Hit> _search(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final labs = context.read<LabRecordsProvider>().records;
    final meds = context.read<MedicineProvider>().items;
    final hits = <_Hit>[];

    final features = <(IconData, String, String, List<String>, VoidCallback)>[
      (
        Icons.document_scanner_outlined,
        'Scan a lab report'.tr,
        'Feature'.tr,
        ['scan', 'lab', 'report', 'analyse', 'photo', 'ocr'],
        () => openAddResult(context),
      ),
      (
        Icons.show_chart_rounded,
        'Trends'.tr,
        'Feature'.tr,
        ['trend', 'chart', 'history', 'homa', 'score', 'result'],
        () => _tab(1),
      ),
      (
        Icons.restaurant_outlined,
        'Eat and move'.tr,
        'Feature'.tr,
        ['eat', 'food', 'diet', 'sport', 'walk', 'exercise', 'move', 'sugar'],
        () => _go(const WellnessScreen()),
      ),
      (
        Icons.accessibility_new_rounded,
        'Skin and body check'.tr,
        'Feature'.tr,
        ['skin', 'neck', 'dark', 'patch', 'signs', 'acanthosis', 'risk'],
        () => _go(const SkinCheckScreen()),
      ),
      (
        Icons.medical_services_outlined,
        'Find a doctor'.tr,
        'Feature'.tr,
        ['doctor', 'appointment', 'book', 'endocrinologist'],
        () => _go(const FindDoctorScreen()),
      ),
      (
        Icons.medication_outlined,
        'Medicine'.tr,
        'Feature'.tr,
        ['medicine', 'pill', 'prescription', 'reminder'],
        () => _go(const MedicineScreen()),
      ),
      (
        Icons.straighten_rounded,
        'My measurements'.tr,
        'Feature'.tr,
        ['measurement', 'height', 'weight', 'waist', 'age', 'profile'],
        () => _go(const ProfileFormScreen()),
      ),
      (
        Icons.emergency_outlined,
        'Emergency'.tr,
        'Feature'.tr,
        ['emergency', 'ambulance', 'help', 'urgent'],
        () => _go(const EmergencyScreen()),
      ),
    ];
    for (final f in features) {
      if (_match(q, [f.$2, ...f.$4])) {
        hits.add(_Hit(f.$1, f.$2, f.$3, f.$5));
      }
    }

    for (final r in labs.reversed) {
      final date = DateFormat.yMMMd().format(r.date);
      final band = r.homaIrBand?.label ?? '';
      if (_match(q, [
        date,
        band,
        r.homaIr?.toStringAsFixed(2) ?? '',
        'result',
      ])) {
        hits.add(
          _Hit(
            Icons.assignment_outlined,
            r.homaIr == null
                ? 'Result of {date}'.trf({'date': date})
                : 'HOMA-IR ${r.homaIr!.toStringAsFixed(2)}',
            [date, band].where((s) => s.isNotEmpty).join(', '),
            () => _tab(1),
          ),
        );
      }
    }

    for (final m in meds) {
      if (_match(q, [m.name, m.dose, m.note])) {
        hits.add(
          _Hit(
            Icons.medication_outlined,
            m.name.tr,
            '${m.dose}, ${m.time}',
            () => _go(const MedicineScreen()),
          ),
        );
      }
    }

    for (final d in sampleDoctors) {
      if (_match(q, [
        d.name,
        d.specialty,
        d.city,
        d.address,
        d.workTime,
        d.phone,
      ])) {
        hits.add(
          _Hit(
            Icons.person_outline_rounded,
            d.name,
            '${d.specialty.tr}, ${d.city}',
            () => _go(const FindDoctorScreen()),
          ),
        );
      }
    }

    for (final f in foodItems) {
      if (_match(q, [f.name, f.examples, f.name.tr, f.examples.tr])) {
        hits.add(
          _Hit(
            Icons.restaurant_outlined,
            f.name.tr,
            f.level.label,
            () => _go(const WellnessScreen()),
          ),
        );
      }
    }
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final hits = _search(_query);

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    const DsBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: DS.softShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: DS.iconMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                style: DS.text(weight: FontWeight.w600),
                                onChanged: (v) => setState(() => _query = v),
                                decoration: InputDecoration(
                                  hintText: 'Search'.tr,
                                  hintStyle: DS.text(color: DS.iconMuted),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _controller.clear();
                                  _query = '';
                                }),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: DS.iconMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _query.trim().isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Try: scan, food, walk, doctor, medicine, or a date.'
                              .tr,
                          style: DS.text(
                            size: 15,
                            weight: FontWeight.w500,
                            color: DS.muted,
                            height: 1.5,
                          ),
                        ),
                      )
                    : hits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No match for "{v}".'.trf({'v': _query.trim()}),
                          style: DS.text(color: DS.muted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                        itemCount: hits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = hits[i];
                          return DsCard(
                            radius: 22,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            onTap: h.onTap,
                            child: Row(
                              children: [
                                DsIconBadge(icon: h.icon, size: 42),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.title,
                                        style: DS.text(
                                          size: 15.5,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        h.subtitle,
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
                                  color: DS.iconMuted,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
