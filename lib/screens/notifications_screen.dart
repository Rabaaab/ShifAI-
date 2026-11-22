import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/activity_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notices.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../widgets/ds_widgets.dart';
import 'find_doctor_screen.dart';
import 'medicine_screen.dart';
import 'wellness_screen.dart';

/// Current notifications, built from what is in the app (see notices.dart).
List<AppNotice> watchNotices(BuildContext context) {
  final now = DateTime.now();
  return buildNotices(
    records: context.watch<LabRecordsProvider>().records,
    appointment: context.watch<AppointmentProvider>().appointment,
    medicines: context.watch<MedicineProvider>().items,
    medicineReminders: context.watch<SettingsProvider>().medicineReminders,
    weekMinutes: context.watch<ActivityProvider>().minutesThisWeek(now),
    now: now,
  );
}

/// Number of notifications not yet opened.
int unseenCount(BuildContext context, List<AppNotice> notices) {
  final settings = context.watch<SettingsProvider>();
  return notices.where((n) => !settings.hasSeen(n.id)).length;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotice> _shown = const [];
  Set<String> _wasUnseen = {};
  bool _marked = false;

  void _open(AppNotice n) {
    final Widget? screen = switch (n.kind) {
      NoticeKind.medicine => const MedicineScreen(),
      NoticeKind.doctor => const FindDoctorScreen(),
      NoticeKind.activity => const WellnessScreen(startOnMove: true),
      _ => null,
    };
    if (n.kind == NoticeKind.lab) {
      openAddResult(context);
    } else if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final notices = watchNotices(context);

    // Remember which were new when the screen opened, then mark them read.
    if (!_marked) {
      _marked = true;
      _wasUnseen = notices
          .where((n) => !settings.hasSeen(n.id))
          .map((n) => n.id)
          .toSet();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) settings.markSeen(notices.map((n) => n.id));
      });
    }
    _shown = notices;

    IconData iconFor(NoticeKind k) => switch (k) {
      NoticeKind.appointment => Icons.event_available_outlined,
      NoticeKind.medicine => Icons.medication_outlined,
      NoticeKind.lab => Icons.document_scanner_outlined,
      NoticeKind.doctor => Icons.medical_services_outlined,
      NoticeKind.activity => Icons.directions_walk_rounded,
    };

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
              const DsTitle('Your', 'notifications', size: 36),
              const SizedBox(height: 22),
              if (_shown.isEmpty)
                DsCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const DsIconBadge(
                        icon: Icons.notifications_none_rounded,
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nothing new'.tr,
                        style: DS.text(size: 19, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reminders about your tests, appointment, medicine and '
                                'activity show up here.'
                            .tr,
                        textAlign: TextAlign.center,
                        style: DS.text(
                          size: 14.5,
                          weight: FontWeight.w500,
                          color: DS.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final n in _shown) ...[
                  DsCard(
                    radius: 24,
                    padding: const EdgeInsets.all(16),
                    onTap: () => _open(n),
                    child: Row(
                      children: [
                        DsIconBadge(icon: iconFor(n.kind), size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: DS.text(
                                  size: 15.5,
                                  weight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: DS.text(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: DS.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_wasUnseen.contains(n.id))
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: DS.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 10),
              Text(
                'These reminders appear inside the app. Alerts on your phone '
                        'screen are not set up yet.'
                    .tr,
                textAlign: TextAlign.center,
                style: DS.text(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
