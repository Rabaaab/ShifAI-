import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../utils/share_summary.dart';
import '../widgets/ds_widgets.dart';
import 'emergency_screen.dart';
import 'find_doctor_screen.dart';
import 'lab_entry_form_screen.dart';
import 'medicine_screen.dart';
import 'notifications_screen.dart';
import 'profile_form_screen.dart';
import 'search_screen.dart';
import 'skin_check_screen.dart';
import 'wellness_screen.dart';

/// "Show all" of the quick actions: every feature in one place.
class ShortcutsScreen extends StatelessWidget {
  const ShortcutsScreen({super.key});

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _tab(BuildContext context, int tab) {
    context.read<NavProvider>().setTab(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final labs = context.read<LabRecordsProvider>();

    final items = <(IconData, String, String, VoidCallback, Color)>[
      (
        Icons.document_scanner_outlined,
        'Scan a report'.tr,
        'Read a lab report from a photo'.tr,
        () => openAddResult(context),
        DS.navy,
      ),
      (
        Icons.edit_outlined,
        'Type in a result'.tr,
        'Enter the values yourself'.tr,
        () => _go(context, const LabEntryFormScreen()),
        DS.navy,
      ),
      (
        Icons.show_chart_rounded,
        'Trends'.tr,
        'Your results over time'.tr,
        () => _tab(context, 1),
        DS.navy,
      ),
      (
        Icons.share_outlined,
        'Share'.tr,
        'Send a summary on WhatsApp'.tr,
        () {
          if (labs.records.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Add a result first, then you can share it.'.tr),
              ),
            );
          } else {
            shareSummaryOnWhatsApp(context, labs.records.last);
          }
        },
        DS.navy,
      ),
      (
        Icons.restaurant_outlined,
        'Eat and move'.tr,
        'Food and activity guidance'.tr,
        () => _go(context, const WellnessScreen()),
        DS.navy,
      ),
      (
        Icons.accessibility_new_rounded,
        'Skin and body check'.tr,
        'Signs of insulin resistance'.tr,
        () => _go(context, const SkinCheckScreen()),
        DS.navy,
      ),
      (
        Icons.medical_services_outlined,
        'Find a doctor'.tr,
        'Book an appointment'.tr,
        () => _go(context, const FindDoctorScreen()),
        DS.navy,
      ),
      (
        Icons.medication_outlined,
        'Medicine'.tr,
        'Your daily schedule'.tr,
        () => _go(context, const MedicineScreen()),
        DS.navy,
      ),
      (
        Icons.straighten_rounded,
        'My measurements'.tr,
        'Age, height, weight, waist'.tr,
        () => _go(context, const ProfileFormScreen()),
        DS.navy,
      ),
      (
        Icons.search_rounded,
        'Search'.tr,
        'Find anything in the app'.tr,
        () => _go(context, const SearchScreen()),
        DS.navy,
      ),
      (
        Icons.notifications_none_rounded,
        'Notifications'.tr,
        'Reminders and updates'.tr,
        () => _go(context, const NotificationsScreen()),
        DS.navy,
      ),
      (
        Icons.emergency_outlined,
        'Emergency'.tr,
        'Call for help'.tr,
        () => _go(context, const EmergencyScreen()),
        DS.emergency,
      ),
    ];

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: DsBackButton(),
              ),
              const SizedBox(height: 26),
              const DsTitle('All', 'shortcuts', size: 36),
              const SizedBox(height: 22),
              for (final item in items) ...[
                DsCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  onTap: item.$4,
                  child: Row(
                    children: [
                      DsIconBadge(
                        icon: item.$1,
                        size: 46,
                        color: item.$5,
                        background: item.$5 == DS.emergency
                            ? DS.redTint
                            : DS.skyTint,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: DS.text(size: 16, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$3,
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
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
