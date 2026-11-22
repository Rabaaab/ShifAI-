import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../services/lab_ocr_service.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import 'lab_entry_form_screen.dart';

/// Step 1 of the scan flow: photo capture + on-device OCR of a printed lab
/// report. Camera and OCR (Google ML Kit) only exist on Android/iOS, so this
/// screen is only opened there (see utils/open_add_result.dart).
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
        setState(
          () => _error =
              "Couldn't find glucose, insulin or HbA1c in this photo. Try a "
                      'clearer, well-lit photo, or type the values in.'
                  .tr,
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LabEntryFormScreen(
            fromScan: true,
            initialGlucose: result.glucoseValue,
            initialGlucoseUnit: result.glucoseUnit,
            initialInsulin: result.insulinValue,
            initialInsulinUnit: result.insulinUnit,
            initialHba1c: result.hba1cPercent,
            initialTriglycerides: result.triglyceridesValue,
            initialTriglyceridesUnit: result.triglyceridesUnit,
            initialHdl: result.hdlValue,
            initialHdlUnit: result.hdlUnit,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error =
            'Could not read this image. Try again or type the values in.'.tr;
      });
    }
  }

  void _enterManually() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LabEntryFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const DsBackButton(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: DS.skyTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Step 1 of 2'.tr,
                        style: DS.text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: DS.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DsTitle('Scan your', 'lab report', size: 36),
                const SizedBox(height: 22),
                Expanded(child: _viewfinder()),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: DS.text(size: 14, color: DS.redText, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewfinder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14335F), Color(0xFF0A1E3E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47001E50),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_image != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.85,
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            )
          else
            Align(
              alignment: const Alignment(0, -0.45),
              child: Transform.rotate(
                angle: -2 * math.pi / 180,
                child: const _Paper(),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 40, 36, 150),
              child: CustomPaint(painter: _FramePainter()),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.42),
            child: _processing
                ? const CircularProgressIndicator(color: Colors.white)
                : (_image == null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Fit the page in the frame'.tr,
                            style: DS.text(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _roundButton(
                  Icons.edit_outlined,
                  'Type the values in'.tr,
                  _enterManually,
                ),
                _shutter(),
                _roundButton(
                  Icons.photo_library_outlined,
                  'Choose from the gallery'.tr,
                  _processing ? null : () => _capture(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 25, color: Colors.white),
        ),
      ),
    );
  }

  Widget _shutter() {
    return Semantics(
      button: true,
      label: 'Take a photo'.tr,
      child: GestureDetector(
        onTap: _processing ? null : () => _capture(ImageSource.camera),
        child: Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DS.sky, width: 3),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Little sheet of paper drawn in the viewfinder (an illustration, not a
/// preview of the camera).
class _Paper extends StatelessWidget {
  const _Paper();

  Widget _row(double a, double b, {bool tint = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    decoration: BoxDecoration(
      color: tint ? DS.skyTint : null,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: a,
          height: 6,
          decoration: BoxDecoration(
            color: tint ? DS.sky : const Color(0xFFD8E3EE),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Container(
          width: b,
          height: 6,
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
    width: 200,
    height: 262,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFC7D6E6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: 176,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECF5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: 144,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECF5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 16),
        _row(76, 28, tint: true),
        const SizedBox(height: 11),
        _row(92, 24),
        const SizedBox(height: 11),
        _row(60, 24, tint: true),
        const SizedBox(height: 11),
        _row(84, 26),
      ],
    ),
  );
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DS.sky
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 38.0;
    const r = 20.0;
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h - len)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - len, h),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(len, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..lineTo(0, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
