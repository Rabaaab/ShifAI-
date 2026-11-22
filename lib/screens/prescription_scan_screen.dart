import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../services/prescription_parser.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import 'prescription_confirm_screen.dart';

/// Photo of a printed prescription, read on the phone (Google ML Kit), then
/// checked by the person before anything is added. Android and iOS only.
class PrescriptionScanScreen extends StatefulWidget {
  const PrescriptionScanScreen({super.key});

  @override
  State<PrescriptionScanScreen> createState() => _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState extends State<PrescriptionScanScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _read(ImageSource source) async {
    setState(() => _error = null);
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final text = (await _recognizer.processImage(
        InputImage.fromFile(File(picked.path)),
      )).text;
      if (!mounted) return;
      setState(() => _busy = false);
      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PrescriptionConfirmScreen(
            candidates: PrescriptionParser.parse(text),
            rawText: text,
          ),
        ),
      );
      if (added == true && mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not read this image. Try again with better light.'.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DsBackButton(),
                const SizedBox(height: 26),
                const DsTitle('Scan your', 'prescription', size: 36),
                const SizedBox(height: 14),
                Text(
                  'Printed prescriptions work best. Handwriting is hard to '
                          'read, so you always check the result before it is added.'
                      .tr,
                  style: DS.text(
                    size: 15.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                if (_error != null) ...[
                  Text(_error!, style: DS.text(size: 14, color: DS.redText)),
                  const SizedBox(height: 12),
                ],
                DsPrimaryButton(
                  label: 'Take a photo'.tr,
                  icon: Icons.photo_camera_outlined,
                  loading: _busy,
                  onPressed: () => _read(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                DsOutlineButton(
                  label: 'Choose from the gallery'.tr,
                  icon: Icons.photo_library_outlined,
                  onPressed: _busy ? null : () => _read(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
