import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/lab_ocr_service.dart';
import '../theme/app_colors.dart';
import 'lab_entry_form_screen.dart';

/// Photo capture + on-device OCR for a printed lab report.
/// Camera & OCR (Google ML Kit) are Android/iOS-only — this screen is only
/// reachable from platforms that support it (see HomeScreen's platform guard).
class LabScanScreen extends StatefulWidget {
  const LabScanScreen({super.key});

  @override
  State<LabScanScreen> createState() => _LabScanScreenState();
}

class _LabScanScreenState extends State<LabScanScreen> {
  final _picker = ImagePicker();
  final _ocr = LabOcrService();

  File? _image;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    setState(() => _error = null);
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _processing = true;
    });

    try {
      final result = await _ocr.extractFromImage(_image!);
      if (!mounted) return;
      setState(() => _processing = false);

      if (!result.hasAnyValue) {
        setState(() => _error =
            "Couldn't find glucose, insulin or HbA1c values in this photo. "
            'Try a clearer, well-lit photo, or enter the values manually.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LabEntryFormScreen(
          fromScan: true,
          initialGlucose: result.glucoseValue,
          initialGlucoseUnit: result.glucoseUnit,
          initialInsulin: result.insulinValue,
          initialInsulinUnit: result.insulinUnit,
          initialHba1c: result.hba1cPercent,
        ),
      ));
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Could not read this image. Please try again or enter values manually.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan lab report')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.pastel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pastelBorder),
                ),
                child: _processing
                    ? const Center(child: CircularProgressIndicator())
                    : _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, fit: BoxFit.contain),
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.document_scanner_outlined,
                                      size: 56, color: AppColors.accentBlue),
                                  SizedBox(height: 12),
                                  Text(
                                    'Photograph a printed lab report showing '
                                    'glucose, insulin, or HbA1c.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : () => _capture(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : () => _capture(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LabEntryFormScreen()),
              ),
              child: const Text('Enter values manually instead'),
            ),
          ],
        ),
      ),
    );
  }
}
