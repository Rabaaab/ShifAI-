import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/l10n.dart';
import '../providers/medicine_provider.dart';
import '../services/prescription_parser.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

class _Row {
  _Row(MedicineCandidate c)
    : name = TextEditingController(text: c.name),
      dose = TextEditingController(text: c.dose),
      note = c.note,
      times = [...c.times],
      guessed = c.timesGuessed;

  final TextEditingController name;
  final TextEditingController dose;
  final String note;
  final List<String> times;
  final bool guessed;
  bool selected = true;

  void dispose() {
    name.dispose();
    dose.dispose();
  }
}

/// Check what was read from a prescription before it goes on the schedule.
/// OCR only suggests; nothing is added until the person confirms.
class PrescriptionConfirmScreen extends StatefulWidget {
  const PrescriptionConfirmScreen({
    super.key,
    required this.candidates,
    required this.rawText,
  });
  final List<MedicineCandidate> candidates;
  final String rawText;

  @override
  State<PrescriptionConfirmScreen> createState() =>
      _PrescriptionConfirmScreenState();
}

class _PrescriptionConfirmScreenState extends State<PrescriptionConfirmScreen> {
  late final List<_Row> _rows = widget.candidates.map(_Row.new).toList();
  bool _saving = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  static const _slots = ['08:00', '13:00', '20:00'];

  Future<void> _addAll() async {
    final chosen = _rows
        .where((r) => r.selected && r.name.text.trim().isNotEmpty)
        .toList();
    if (chosen.isEmpty) return;
    final meds = context.read<MedicineProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    var count = 0;
    for (final r in chosen) {
      for (final t in r.times) {
        await meds.add(
          Medicine(
            id: const Uuid().v4(),
            name: r.name.text.trim(),
            dose: r.dose.text.trim(),
            note: r.note,
            time: t,
          ),
        );
        count++;
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          (count == 1 ? '1 reminder added.' : '{count} reminders added.').trf({
            'count': count,
          }),
        ),
      ),
    );
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _rows.where((r) => r.selected).length;

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
                    const SizedBox(height: 24),
                    const DsTitle('Check your', 'prescription', size: 36),
                    const SizedBox(height: 12),
                    Text(
                      _rows.isEmpty
                          ? 'We could not find a medicine and a dose in this '
                                    'photo. Try a clearer, straight photo, or add '
                                    'it by hand.'
                                .tr
                          : 'Compare with the paper. Fix anything that is '
                                    'wrong, then add.'
                                .tr,
                      style: DS.text(
                        size: 15.5,
                        weight: FontWeight.w500,
                        color: DS.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final r in _rows) ...[
                      DsCard(
                        radius: 24,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: r.selected,
                                  activeColor: DS.navy,
                                  onChanged: (v) =>
                                      setState(() => r.selected = v ?? false),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: r.name,
                                    style: DS.text(
                                      size: 16,
                                      weight: FontWeight.w800,
                                    ),
                                    decoration: dsFieldDecoration(
                                      hint: 'Medicine name'.tr,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.dose,
                              style: DS.text(weight: FontWeight.w600),
                              decoration: dsFieldDecoration(
                                hint: 'Dose'.tr,
                                vertical: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              r.guessed
                                  ? 'No schedule found: choose the times'.tr
                                  : 'Times, read from the paper'.tr,
                              style: DS.text(
                                size: 13,
                                weight: FontWeight.w600,
                                color: r.guessed ? DS.amberText : DS.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final slot in _slots)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      r.times.contains(slot)
                                          ? r.times.remove(slot)
                                          : r.times.add(slot);
                                      r.times.sort();
                                    }),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: r.times.contains(slot)
                                            ? DS.navy
                                            : DS.field,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        slot,
                                        style: DS.text(
                                          size: 14.5,
                                          weight: FontWeight.w700,
                                          color: r.times.contains(slot)
                                              ? Colors.white
                                              : DS.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          'Show the text we read'.tr,
                          style: DS.text(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: DS.navy,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SelectableText(
                              widget.rawText.isEmpty
                                  ? '(nothing)'.tr
                                  : widget.rawText,
                              style: DS.text(
                                size: 13,
                                weight: FontWeight.w500,
                                color: DS.muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: _rows.isEmpty
                    ? DsPrimaryButton(
                        label: 'Back'.tr,
                        onPressed: () => Navigator.of(context).pop(false),
                      )
                    : DsPrimaryButton(
                        label: selectedCount == 0
                            ? 'Choose a medicine'.tr
                            : 'Add {selectedCount} to my schedule'.trf({
                                'selectedCount': selectedCount,
                              }),
                        loading: _saving,
                        onPressed: selectedCount == 0 ? null : _addAll,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
