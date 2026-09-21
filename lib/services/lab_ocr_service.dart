import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/lab_record.dart';

/// Best-effort extraction of glucose / insulin / HbA1c values from a photo
/// of a printed lab report. Handles English and French lab terminology
/// (glycémie, insuline, hémoglobine glyquée) since Moroccan lab reports are
/// commonly French-language. Always shown to the user for confirmation
/// before being saved — OCR on a real-world printed report is not perfect.
class LabOcrResult {
  final double? glucoseValue;
  final GlucoseUnit? glucoseUnit;
  final double? insulinValue;
  final InsulinUnit? insulinUnit;
  final double? hba1cPercent;
  final String rawText;

  LabOcrResult({
    this.glucoseValue,
    this.glucoseUnit,
    this.insulinValue,
    this.insulinUnit,
    this.hba1cPercent,
    required this.rawText,
  });

  bool get hasAnyValue =>
      glucoseValue != null || insulinValue != null || hba1cPercent != null;
}

class LabOcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static final _numberPattern = RegExp(r'(\d+[.,]?\d*)');

  static final _glucosePattern =
      RegExp(r'glyc[ée]mie|glucose', caseSensitive: false);
  static final _insulinPattern =
      RegExp(r'insulin[ei]?', caseSensitive: false);
  static final _hba1cPattern = RegExp(
    r'hba1c|h[ée]moglobine\s*glyqu[ée]e|hemoglobine glycosylee',
    caseSensitive: false,
  );

  Future<LabOcrResult> extractFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(inputImage);
    return _parse(recognized.text);
  }

  LabOcrResult _parse(String text) {
    double? glucoseValue;
    GlucoseUnit? glucoseUnit;
    double? insulinValue;
    InsulinUnit? insulinUnit;
    double? hba1c;

    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();

      if (glucoseValue == null && _glucosePattern.hasMatch(lower)) {
        final n = _firstNumber(line);
        if (n != null) {
          glucoseValue = n;
          glucoseUnit = _detectGlucoseUnit(lower) ?? _guessGlucoseUnit(n);
        }
      }

      if (insulinValue == null && _insulinPattern.hasMatch(lower)) {
        final n = _firstNumber(line);
        if (n != null) {
          insulinValue = n;
          insulinUnit = _detectInsulinUnit(lower) ?? InsulinUnit.uiuml;
        }
      }

      if (hba1c == null && _hba1cPattern.hasMatch(lower)) {
        final n = _firstNumber(line);
        if (n != null) hba1c = n;
      }
    }

    return LabOcrResult(
      glucoseValue: glucoseValue,
      glucoseUnit: glucoseUnit,
      insulinValue: insulinValue,
      insulinUnit: insulinUnit,
      hba1cPercent: hba1c,
      rawText: text,
    );
  }

  double? _firstNumber(String line) {
    final match = _numberPattern.firstMatch(line);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  GlucoseUnit? _detectGlucoseUnit(String lowerLine) {
    if (lowerLine.contains('g/l')) return GlucoseUnit.gl;
    if (lowerLine.contains('mmol')) return GlucoseUnit.mmoll;
    if (lowerLine.contains('mg/dl') || lowerLine.contains('mg/dL')) {
      return GlucoseUnit.mgdl;
    }
    return null;
  }

  /// When no unit is printed next to the number, guess from the typical
  /// physiological range: g/L values look like 0.7–1.3, mg/dL like 70–130,
  /// mmol/L like 4–8.
  GlucoseUnit _guessGlucoseUnit(double value) {
    if (value < 3) return GlucoseUnit.gl;
    if (value < 15) return GlucoseUnit.mmoll;
    return GlucoseUnit.mgdl;
  }

  InsulinUnit? _detectInsulinUnit(String lowerLine) {
    if (lowerLine.contains('pmol')) return InsulinUnit.pmoll;
    if (lowerLine.contains('uiu') || lowerLine.contains('µiu') ||
        lowerLine.contains('miu') || lowerLine.contains('ui/ml')) {
      return InsulinUnit.uiuml;
    }
    return null;
  }

  void dispose() {
    _recognizer.close();
  }
}
