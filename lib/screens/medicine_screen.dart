import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/l10n.dart';
import '../providers/appointment_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import 'prescription_scan_entry.dart';

/// Daily medicine schedule. ShifAI never suggests medicines: the doctor
/// decides and the patient keeps this list.
class MedicineScreen extends StatelessWidget {
  const MedicineScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final provider = context.read<MedicineProvider>();
    final medicine = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DS.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const _AddMedicineSheet(),
    );
    if (medicine != null) await provider.add(medicine);
  }

  Future<void> _remove(BuildContext context, Medicine m) async {
    final provider = context.read<MedicineProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove {name}?'.trf({'name': m.name}),
          style: DS.text(weight: FontWeight.w800),
        ),
        content: Text(
          'It will be removed from your daily schedule.'.tr,
          style: DS.text(size: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove'.tr, style: TextStyle(color: DS.redText)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.remove(m.id);
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicineProvider>();
    final settings = context.watch<SettingsProvider>();
    final doctor = context.watch<AppointmentProvider>().appointment?.doctor;
    final now = DateTime.now();
    final items = meds.items;
    final taken = meds.takenCount(now);
    final nextId = items
        .where((m) => !m.takenToday(now))
        .map((m) => m.id)
        .firstOrNull;

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: DsBackButton(),
                    ),
                    const SizedBox(height: 26),
                    const DsTitle('My', 'medicine'),
                    if (doctor != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          DsDoctorAvatar(asset: doctor.photo, size: 32),
                          const SizedBox(width: 10),
                          Text(
                            'Added by {name}'.trf({'name': doctor.name}),
                            style: DS.text(
                              size: 14,
                              weight: FontWeight.w600,
                              color: DS.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    DsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today'.tr,
                                      style: DS.text(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: DS.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '{taken} of {length} taken'.trf({
                                        'taken': taken,
                                        'length': items.length,
                                      }),
                                      style: DS.text(
                                        size: 28,
                                        weight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (items.isNotEmpty && taken == items.length)
                                DsPill(
                                  'All done'.tr,
                                  background: DS.greenTint,
                                  foreground: DS.greenText,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: items.isEmpty ? 0 : taken / items.length,
                              minHeight: 10,
                              color: DS.navy,
                              backgroundColor: DS.skyTint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      DsCard(
                        child: Text(
                          'No medicine yet. Add the ones your doctor gave you.'
                              .tr,
                          style: DS.text(color: DS.muted, height: 1.45),
                        ),
                      ),
                    for (final m in items) ...[
                      _MedicineRow(
                        medicine: m,
                        takenToday: m.takenToday(now),
                        isNext: m.id == nextId,
                        onMark: () => meds.markTaken(m.id),
                        onUndo: () => meds.markTaken(m.id, taken: false),
                        onRemove: () => _remove(context, m),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    DsCard(
                      radius: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const DsIconBadge(
                            icon: Icons.notifications_none_rounded,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reminders'.tr,
                                  style: DS.text(
                                    size: 16,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  settings.medicineReminders
                                      ? 'Shown in your notifications'.tr
                                      : 'Off'.tr,
                                  style: DS.text(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: DS.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DsSwitch(
                            value: settings.medicineReminders,
                            onChanged: settings.setMedicineReminders,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: DsPrimaryButton(
                        label: 'Add medicine'.tr,
                        icon: Icons.add_rounded,
                        height: 58,
                        onPressed: () => _add(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DsOutlineButton(
                        label: 'Scan prescription'.tr,
                        fontSize: 14.5,
                        icon: Icons.document_scanner_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrescriptionScanScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({
    required this.medicine,
    required this.takenToday,
    required this.isNext,
    required this.onMark,
    required this.onUndo,
    required this.onRemove,
  });
  final Medicine medicine;
  final bool takenToday;
  final bool isNext;
  final VoidCallback onMark;
  final VoidCallback onUndo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final status = takenToday ? 'Taken'.tr : (isNext ? 'Next'.tr : 'Later'.tr);
    final statusColor = takenToday
        ? DS.greenText
        : (isNext ? DS.navy : DS.iconMuted);
    final badge = takenToday
        ? const DsIconBadge(
            icon: Icons.check_rounded,
            size: 48,
            background: DS.greenTint,
            color: DS.greenText,
          )
        : DsIconBadge(
            icon: Icons.medication_outlined,
            size: 48,
            background: isNext ? DS.skyTint : DS.field,
            color: isNext ? DS.navy : DS.iconMuted,
          );

    final note = [
      medicine.dose,
      medicine.note.tr,
    ].where((s) => s.isNotEmpty).join(', ');

    return GestureDetector(
      onLongPress: onRemove,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isNext ? Border.all(color: DS.navy, width: 2) : null,
          boxShadow: isNext ? DS.cardShadow(0.12) : DS.softShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                badge,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name.tr,
                        style: DS.text(size: 16, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: DS.text(
                          size: 13.5,
                          weight: FontWeight.w500,
                          color: DS.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      medicine.time,
                      style: DS.text(size: 15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: takenToday ? onUndo : null,
                      child: Text(
                        status,
                        style: DS.text(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isNext) ...[
              const SizedBox(height: 14),
              DsPrimaryButton(
                label: 'Mark as taken'.tr,
                height: 50,
                onPressed: onMark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddMedicineSheet extends StatefulWidget {
  const _AddMedicineSheet();

  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _note = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the medicine name.'.tr);
      return;
    }
    Navigator.pop(
      context,
      Medicine(
        id: const Uuid().v4(),
        name: _name.text.trim(),
        dose: _dose.text.trim(),
        note: _note.text.trim(),
        time: _timeText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add medicine'.tr,
              style: DS.text(size: 24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              style: DS.text(weight: FontWeight.w600),
              decoration: dsFieldDecoration(hint: 'Medicine name'.tr),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dose,
              style: DS.text(weight: FontWeight.w600),
              decoration: dsFieldDecoration(
                hint: 'Dose, for example 500 mg'.tr,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: DS.text(weight: FontWeight.w600),
              decoration: dsFieldDecoration(
                hint: 'Note, for example with lunch'.tr,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: DS.field,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: DS.navy),
                    const SizedBox(width: 12),
                    Text(
                      'Time  {_timeText}'.trf({'_timeText': _timeText}),
                      style: DS.text(size: 17, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: DS.text(size: 13.5, color: DS.redText)),
            ],
            const SizedBox(height: 20),
            DsPrimaryButton(label: 'Save'.tr, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
