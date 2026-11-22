import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../utils/share_summary.dart';
import '../widgets/band_style.dart';
import '../widgets/ds_widgets.dart';
import '../widgets/language_picker.dart';
import 'book_screen.dart';
import 'emergency_screen.dart';
import 'find_doctor_screen.dart';
import 'lab_entry_form_screen.dart';
import 'medicine_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'shortcuts_screen.dart';
import 'skin_check_screen.dart';
import 'wellness_screen.dart';

/// Home. Three states, step by step:
///  1. first visit: no result yet, no doctor
///  2. has results, no doctor yet
///  3. following a doctor (an appointment is booked): Doctor, Medicine,
///     Report and Emergency shortcuts and the upcoming appointment appear.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _firstName(String displayName) {
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    return first == 'ShifAI' || first.isEmpty ? '' : first;
  }

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Morning'.tr;
    if (now.hour < 18) return 'Afternoon'.tr;
    return 'Evening'.tr;
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(what)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final labs = context.watch<LabRecordsProvider>();
    final appt = context.watch<AppointmentProvider>();
    final nav = context.read<NavProvider>();

    final withHoma = labs.records.where((r) => r.homaIr != null).toList();
    final latest = withHoma.isEmpty ? null : withHoma.last;
    final following = appt.followingDoctor;
    final firstVisit = labs.records.isEmpty && !following;
    final name = _firstName(auth.displayName);
    final now = DateTime.now();
    final notices = watchNotices(context);
    final unseen = unseenCount(context, notices);

    final title = firstVisit
        ? (name.isEmpty ? 'Welcome'.tr : 'Welcome, {name}'.trf({'name': name}))
        : (name.isEmpty ? _greeting(now) : '${_greeting(now)}, $name');

    final actions = following
        ? [
            DsQuickAction(
              icon: Icons.medical_services_outlined,
              label: 'Doctor'.tr,
              onTap: () => _push(context, const FindDoctorScreen()),
            ),
            DsQuickAction(
              icon: Icons.medication_outlined,
              label: 'Medicine'.tr,
              onTap: () => _push(context, const MedicineScreen()),
            ),
            DsQuickAction(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Report'.tr,
              onTap: () => nav.setTab(1),
            ),
            DsQuickAction(
              icon: Icons.emergency_outlined,
              label: 'Emergency'.tr,
              iconColor: DS.emergency,
              onTap: () => _push(context, const EmergencyScreen()),
            ),
          ]
        : [
            DsQuickAction(
              icon: Icons.document_scanner_outlined,
              label: 'Scan'.tr,
              onTap: () => openAddResult(context),
            ),
            DsQuickAction(
              icon: Icons.edit_outlined,
              label: 'Type in'.tr,
              onTap: () => _push(context, const LabEntryFormScreen()),
            ),
            DsQuickAction(
              icon: Icons.show_chart_rounded,
              label: 'Trends'.tr,
              onTap: () => nav.setTab(1),
            ),
            DsQuickAction(
              icon: Icons.share_outlined,
              label: 'Share'.tr,
              onTap: () {
                if (labs.records.isEmpty) {
                  _soon(
                    context,
                    'Add a result first, then you can share it.'.tr,
                  );
                } else {
                  shareSummaryOnWhatsApp(context, labs.records.last);
                }
              },
            ),
          ];

    return DsBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Image.asset(
                      'assets/images/shifai_logo.png',
                      width: 112,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      semanticLabel: 'ShifAI',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const LanguageButton(),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: unseen == 0
                      ? 'Notifications'.tr
                      : 'Notifications, {unseen} new'.trf({'unseen': unseen}),
                  child: GestureDetector(
                    onTap: () => _push(context, const NotificationsScreen()),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DS.navy.withValues(alpha: 0.10),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 25,
                            color: DS.ink,
                          ),
                        ),
                        if (unseen > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: DS.red,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: DS.bgTop, width: 2),
                              ),
                              child: Text(
                                '$unseen',
                                style: DS.text(
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DS.text(
                    size: 24,
                    weight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  firstVisit
                      ? "Let's look at your numbers".tr
                      : 'Your health at a glance'.tr,
                  style: DS.text(
                    size: 14.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Search'.tr,
              child: GestureDetector(
                onTap: () => _push(context, const SearchScreen()),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: DS.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: DS.iconMuted,
                      ),
                      const SizedBox(width: 12),
                      Text('Search'.tr, style: DS.text(color: DS.iconMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            DsSectionHeader(
              'Quick actions'.tr,
              action: 'Show all'.tr,
              onAction: () => _push(context, const ShortcutsScreen()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions,
            ),
            const SizedBox(height: 24),
            if (following)
              _Banner(
                title: 'Keep your results up to date'.tr,
                button: 'Scan report'.tr,
                onTap: () => openAddResult(context),
                doctorPhoto: appt.appointment!.doctor.photo,
              )
            else
              _Banner(
                title: firstVisit
                    ? 'Scan your first lab report'.tr
                    : 'Scan your next lab report'.tr,
                button: 'Scan now'.tr,
                onTap: () => openAddResult(context),
              ),
            if (following) ...[
              const SizedBox(height: 24),
              DsSectionHeader('Upcoming appointment'.tr),
              _AppointmentCard(appointment: appt.appointment!),
            ],
            const SizedBox(height: 24),
            DsSectionHeader('For you'.tr),
            const SizedBox(height: 4),
            _FeatureCard(
              icon: Icons.restaurant_outlined,
              title: 'Eat and move'.tr,
              subtitle: 'Food and activity tips to lower your risk'.tr,
              onTap: () => _push(context, const WellnessScreen()),
            ),
            if (labs.records.isEmpty) ...[
              const SizedBox(height: 10),
              _FeatureCard(
                icon: Icons.accessibility_new_rounded,
                title: 'No blood test yet?'.tr,
                subtitle: 'Check your skin signs and risk factors'.tr,
                onTap: () => _push(context, const SkinCheckScreen()),
              ),
            ],
            if (firstVisit) ...[
              const SizedBox(height: 24),
              Text(
                'How it works'.tr,
                style: DS.text(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Step(
                      icon: Icons.photo_camera_outlined,
                      label: 'Scan'.tr,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _Step(
                      icon: Icons.check_box_outlined,
                      label: 'Check'.tr,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _Step(
                      icon: Icons.show_chart_rounded,
                      label: 'Your score'.tr,
                    ),
                  ),
                ],
              ),
            ],
            if (latest != null) ...[
              const SizedBox(height: 24),
              DsSectionHeader(
                'Latest result'.tr,
                action: 'Show all'.tr,
                onAction: () => nav.setTab(1),
              ),
              _LatestResultCard(record: latest, onTap: () => nav.setTab(1)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.button,
    required this.onTap,
    this.doctorPhoto,
  });
  final String title;
  final String button;
  final VoidCallback onTap;
  final String? doctorPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      decoration: BoxDecoration(
        gradient: DS.navyGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: DS.cardShadow(0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -60,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.sky.withValues(alpha: 0.24),
              ),
            ),
          ),
          if (doctorPhoto != null)
            Positioned(
              right: 16,
              bottom: -3,
              child: Container(
                width: 128,
                height: 163,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(64),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(61),
                  ),
                  child: Image.asset(
                    doctorPhoto!,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.7),
                    semanticLabel: 'Your doctor'.tr,
                  ),
                ),
              ),
            )
          else
            Positioned(
              right: 26,
              top: 26,
              child: Transform.rotate(
                angle: 7 * math.pi / 180,
                child: const _ReportMock(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    title,
                    style: DS.text(
                      size: 21,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  button: true,
                  label: button,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            button,
                            style: DS.text(
                              size: 15,
                              weight: FontWeight.w700,
                              color: DS.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMock extends StatelessWidget {
  const _ReportMock();

  Widget _row(double a, double b, {bool tint = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(
      color: tint ? DS.skyTint : null,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: a,
          height: 5,
          decoration: BoxDecoration(
            color: tint ? DS.sky : const Color(0xFFD8E3EE),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Container(
          width: b,
          height: 5,
          decoration: BoxDecoration(
            color: tint ? DS.navy : const Color(0xFFC7D6E6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    height: 170,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4D001E3C),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 66,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFC7D6E6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 9),
        Container(
          width: 105,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECF5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 9),
        _row(44, 18, tint: true),
        const SizedBox(height: 9),
        _row(54, 16),
        const SizedBox(height: 9),
        _row(36, 18, tint: true),
      ],
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DsCard(
    radius: 24,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onTap: onTap,
    child: Row(
      children: [
        DsIconBadge(icon: icon, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DS.text(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: DS.text(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: DS.iconMuted),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: DS.softShadow,
    ),
    child: Column(
      children: [
        DsIconBadge(icon: icon, size: 42),
        const SizedBox(height: 10),
        Text(label, style: DS.text(size: 14, weight: FontWeight.w700)),
      ],
    ),
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});
  final Appointment appointment;

  Future<void> _cancel(BuildContext context) async {
    final provider = context.read<AppointmentProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel this appointment?'.tr,
          style: DS.text(weight: FontWeight.w800),
        ),
        content: Text(
          'Your doctor will no longer see your results.'.tr,
          style: DS.text(size: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cancel appointment'.tr,
              style: TextStyle(color: DS.redText),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await provider.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    Widget info(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF44546A)),
        const SizedBox(width: 7),
        Text(
          text,
          style: DS.text(
            size: 13.5,
            weight: FontWeight.w600,
            color: const Color(0xFF44546A),
          ),
        ),
      ],
    );

    return DsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              DsDoctorAvatar(asset: doctor.photo, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: DS.text(size: 16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty.tr,
                      style: DS.text(
                        size: 14,
                        weight: FontWeight.w500,
                        color: DS.muted,
                      ),
                    ),
                  ],
                ),
              ),
              DsPill(
                'Upcoming'.tr,
                background: DS.greenTint,
                foreground: DS.greenText,
                size: 12.5,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              info(
                Icons.calendar_today_outlined,
                DateFormat('d MMM, y').format(appointment.date),
              ),
              info(Icons.schedule_rounded, formatSlotTime(appointment.time)),
              info(Icons.place_outlined, 'Clinic'.tr),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DsOutlineButton(
                  label: 'Cancel'.tr,
                  height: 52,
                  onPressed: () => _cancel(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DsOutlineButton(
                  label: 'Reschedule'.tr,
                  height: 52,
                  color: DS.navy,
                  fill: DS.skyTint,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookScreen(doctor: doctor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard({required this.record, required this.onTap});
  final LabRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final homa = record.homaIr!;
    final band = record.homaIrBand!;
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: _RingPainter(
                progress: (homa / 4.5).clamp(0.04, 1.0),
                color: bandColor(band),
              ),
              child: Center(
                child: Text(
                  homa.toStringAsFixed(1),
                  style: DS.text(
                    size: 22,
                    weight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BandChip(band: band),
                ),
                const SizedBox(height: 8),
                Text(
                  'HOMA-IR, ${DateFormat.yMMMd().format(record.date)}',
                  style: DS.text(
                    size: 14,
                    weight: FontWeight.w500,
                    color: DS.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: DS.iconMuted,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = DS.skyTint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
