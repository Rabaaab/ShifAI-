import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../theme/app_colors.dart';

/// Manual entry / confirmation form for a lab record.
/// Used both for typing values in directly and for reviewing OCR-extracted
/// values before they're saved (OCR suggests, the user always confirms).
class LabEntryFormScreen extends StatefulWidget {
  final double? initialGlucose;
  final GlucoseUnit? initialGlucoseUnit;
  final double? initialInsulin;
  final InsulinUnit? initialInsulinUnit;
  final double? initialHba1c;
  final bool fromScan;

  const LabEntryFormScreen({
    super.key,
    this.initialGlucose,
    this.initialGlucoseUnit,
    this.initialInsulin,
    this.initialInsulinUnit,
    this.initialHba1c,
    this.fromScan = false,
  });

  @override
  State<LabEntryFormScreen> createState() => _LabEntryFormScreenState();
}

class _LabEntryFormScreenState extends State<LabEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _glucoseCtrl;
  late final TextEditingController _insulinCtrl;
  late final TextEditingController _hba1cCtrl;
  late final TextEditingController _notesCtrl;

  late GlucoseUnit _glucoseUnit;
  late InsulinUnit _insulinUnit;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _glucoseCtrl = TextEditingController(
        text: widget.initialGlucose?.toString() ?? '');
    _insulinCtrl = TextEditingController(
        text: widget.initialInsulin?.toString() ?? '');
    _hba1cCtrl =
        TextEditingController(text: widget.initialHba1c?.toString() ?? '');
    _notesCtrl = TextEditingController();
    _glucoseUnit = widget.initialGlucoseUnit ?? GlucoseUnit.gl;
    _insulinUnit = widget.initialInsulinUnit ?? InsulinUnit.uiuml;
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _insulinCtrl.dispose();
    _hba1cCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final glucoseRaw = double.tryParse(_glucoseCtrl.text.replaceAll(',', '.'));
    final insulinRaw = double.tryParse(_insulinCtrl.text.replaceAll(',', '.'));
    final hba1cRaw = double.tryParse(_hba1cCtrl.text.replaceAll(',', '.'));

    final record = LabRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      fastingGlucoseMgdl: glucoseRaw == null
          ? null
          : UnitConverter.glucoseToMgdl(glucoseRaw, _glucoseUnit),
      fastingInsulinUiuml: insulinRaw == null
          ? null
          : UnitConverter.insulinToUiuml(insulinRaw, _insulinUnit),
      hba1cPercent: hba1cRaw,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await context.read<LabRecordsProvider>().addRecord(record);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromScan ? 'Confirm scanned values' : 'Add lab result'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.fromScan)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.pastel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.navy, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Values were read from your photo. Please check them against the printed report before saving.',
                        style: TextStyle(color: AppColors.navy, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),

            _valueWithUnitRow(
              label: 'Fasting glucose',
              controller: _glucoseCtrl,
              unitWidget: DropdownButton<GlucoseUnit>(
                value: _glucoseUnit,
                items: const [
                  DropdownMenuItem(value: GlucoseUnit.gl, child: Text('g/L')),
                  DropdownMenuItem(value: GlucoseUnit.mgdl, child: Text('mg/dL')),
                  DropdownMenuItem(value: GlucoseUnit.mmoll, child: Text('mmol/L')),
                ],
                onChanged: (u) => setState(() => _glucoseUnit = u!),
              ),
            ),
            const SizedBox(height: 16),

            _valueWithUnitRow(
              label: 'Fasting insulin',
              controller: _insulinCtrl,
              unitWidget: DropdownButton<InsulinUnit>(
                value: _insulinUnit,
                items: const [
                  DropdownMenuItem(value: InsulinUnit.uiuml, child: Text('µIU/mL')),
                  DropdownMenuItem(value: InsulinUnit.pmoll, child: Text('pmol/L')),
                ],
                onChanged: (u) => setState(() => _insulinUnit = u!),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Both glucose and insulin are needed to calculate HOMA-IR.',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _hba1cCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'HbA1c (%) — optional'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes — optional'),
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _save,
              child: const Text('Save result'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueWithUnitRow({
    required String label,
    required TextEditingController controller,
    required Widget unitWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: unitWidget,
        ),
      ],
    );
  }
}
