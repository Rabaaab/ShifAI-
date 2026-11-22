import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/doctor.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

/// Book Appointment: details, date and time, and whether to share results.
/// The appointment is a request stored on this device (prototype); the
/// doctor-side confirmation does not exist yet.
class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.doctor});
  final Doctor doctor;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  static const _times = [
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
  ];
  static List<String> get _weekdays => [
    'MON'.tr,
    'TUE'.tr,
    'WED'.tr,
    'THU'.tr,
    'FRI'.tr,
    'SAT'.tr,
    'SUN'.tr,
  ];

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final List<DateTime> _days;
  late DateTime _day;
  late String _time;
  bool _share = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final existing = context.read<AppointmentProvider>().appointment;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    // Weekdays only, starting tomorrow.
    _days = [];
    var cursor = start.add(const Duration(days: 1));
    while (_days.length < 10) {
      if (cursor.weekday <= 5) _days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    _day = _days.first;
    _time = _times[2];
    var name = existing?.patientName ?? '';
    if (name.isEmpty) {
      final display = auth.displayName;
      name = display == 'ShifAI member' ? '' : display;
    }
    _name = TextEditingController(text: name);
    _email = TextEditingController(
      text: (existing?.patientEmail.isNotEmpty ?? false)
          ? existing!.patientEmail
          : (auth.email ?? ''),
    );
    if (existing != null) {
      _share = existing.shareResults;
      final match = _days.where(
        (d) =>
            d.year == existing.date.year &&
            d.month == existing.date.month &&
            d.day == existing.date.day,
      );
      if (match.isNotEmpty) _day = match.first;
      if (_times.contains(existing.time)) _time = existing.time;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter your name and a valid email.'.tr)),
      );
      return;
    }
    final appointments = context.read<AppointmentProvider>();
    final nav = context.read<NavProvider>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await appointments.book(
      Appointment(
        doctorId: widget.doctor.id,
        date: _day,
        time: _time,
        shareResults: _share,
        patientName: name,
        patientEmail: email,
      ),
    );
    nav.setTab(0);
    navigator.popUntil((route) => route.isFirst);
  }

  Widget _clearable(
    TextEditingController controller,
    IconData icon,
    String label,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DS.softShadow,
      ),
      child: TextField(
        controller: controller,
        keyboardType: icon == Icons.mail_outline_rounded
            ? TextInputType.emailAddress
            : TextInputType.name,
        style: DS.text(weight: FontWeight.w600),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 19),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 14),
            child: Icon(icon, size: 21, color: DS.navy),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear {label}'.trf({'label': label}),
                  onPressed: () => setState(controller.clear),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: DS.iconMuted,
                  ),
                ),
        ),
      ),
    );
  }

  /// Horizontal strip of tiles; the selected one is a white card, the others a
  /// soft tint, and the strip fades out at both edges.
  Widget _strip({
    required List<Widget Function(bool selected)> tiles,
    required int selected,
    required ValueChanged<int> onSelect,
    required double tileHeight,
  }) {
    return SizedBox(
      height: tileHeight,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, 0.07, 0.93, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => onSelect(i),
            child: tiles[i](i == selected),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final dayIndex = _days.indexOf(_day);
    final timeIndex = _times.indexOf(_time);

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
              const DsTitle('Book', 'Appointment'),
              const SizedBox(height: 22),
              Row(
                children: [
                  DsDoctorAvatar(asset: doctor.photo, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: DS.text(size: 16.5, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doctor.specialty.tr}, ${doctor.city}',
                          style: DS.text(
                            size: 14,
                            weight: FontWeight.w500,
                            color: DS.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Enter your details'.tr,
                style: DS.text(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF44546A),
                ),
              ),
              const SizedBox(height: 12),
              _clearable(_name, Icons.person_outline_rounded, 'Name'.tr),
              const SizedBox(height: 12),
              _clearable(_email, Icons.mail_outline_rounded, 'Email'.tr),
              const SizedBox(height: 26),
              Text(
                'Pick date and time'.tr,
                style: DS.text(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF44546A),
                ),
              ),
              const SizedBox(height: 12),
              _strip(
                tileHeight: 80,
                selected: dayIndex,
                onSelect: (i) => setState(() => _day = _days[i]),
                tiles: [
                  for (final d in _days)
                    (selected) => Container(
                      width: 62,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : DS.navy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: DS.navy.withValues(alpha: 0.16),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${d.day}',
                            style: DS.text(
                              size: 20,
                              weight: FontWeight.w800,
                              color: selected ? DS.navy : DS.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _weekdays[d.weekday - 1],
                            style: DS.text(
                              size: 12,
                              weight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected ? DS.navy : DS.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _strip(
                tileHeight: 54,
                selected: timeIndex,
                onSelect: (i) => setState(() => _time = _times[i]),
                tiles: [
                  for (final t in _times)
                    (selected) => Container(
                      width: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : DS.navy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: DS.navy.withValues(alpha: 0.16),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        t.startsWith('0') ? t.substring(1) : t,
                        style: DS.text(
                          size: 15,
                          weight: selected ? FontWeight.w800 : FontWeight.w700,
                          color: selected ? DS.navy : DS.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              DsCard(
                radius: 26,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const DsIconBadge(icon: Icons.show_chart_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share my results'.tr,
                            style: DS.text(size: 16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stops if you cancel'.tr,
                            style: DS.text(
                              size: 13.5,
                              weight: FontWeight.w500,
                              color: DS.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DsSwitch(
                      value: _share,
                      onChanged: (v) => setState(() => _share = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              DsPrimaryButton(
                label: 'Book now'.tr,
                loading: _saving,
                onPressed: _book,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'The doctor confirms your request.'.tr,
                  style: DS.text(
                    size: 13.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
