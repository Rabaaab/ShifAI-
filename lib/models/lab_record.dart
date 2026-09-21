enum GlucoseUnit { mgdl, mmoll, gl }

enum InsulinUnit { uiuml, pmoll }

class LabRecord {
  final String id;
  final DateTime date;
  final double? fastingGlucoseMgdl; // stored normalized to mg/dL
  final double? fastingInsulinUiuml; // stored normalized to µIU/mL
  final double? hba1cPercent;
  final String? notes;

  LabRecord({
    required this.id,
    required this.date,
    this.fastingGlucoseMgdl,
    this.fastingInsulinUiuml,
    this.hba1cPercent,
    this.notes,
  });

  /// HOMA-IR = (fasting glucose [mg/dL] x fasting insulin [µIU/mL]) / 405
  /// Standard formula (Matthews et al., 1985), valid when glucose is in mg/dL.
  double? get homaIr {
    if (fastingGlucoseMgdl == null || fastingInsulinUiuml == null) return null;
    return (fastingGlucoseMgdl! * fastingInsulinUiuml!) / 405;
  }

  /// Rough interpretation band for HOMA-IR. Not a diagnosis — always says so.
  HomaIrBand? get homaIrBand {
    final value = homaIr;
    if (value == null) return null;
    if (value < 1.0) return HomaIrBand.optimal;
    if (value < 1.9) return HomaIrBand.normal;
    if (value < 2.9) return HomaIrBand.earlyResistance;
    return HomaIrBand.significantResistance;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'fastingGlucoseMgdl': fastingGlucoseMgdl,
        'fastingInsulinUiuml': fastingInsulinUiuml,
        'hba1cPercent': hba1cPercent,
        'notes': notes,
      };

  factory LabRecord.fromJson(Map<String, dynamic> json) => LabRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        fastingGlucoseMgdl: (json['fastingGlucoseMgdl'] as num?)?.toDouble(),
        fastingInsulinUiuml: (json['fastingInsulinUiuml'] as num?)?.toDouble(),
        hba1cPercent: (json['hba1cPercent'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}

enum HomaIrBand { optimal, normal, earlyResistance, significantResistance }

extension HomaIrBandLabel on HomaIrBand {
  String get label {
    switch (this) {
      case HomaIrBand.optimal:
        return 'Optimal';
      case HomaIrBand.normal:
        return 'Normal';
      case HomaIrBand.earlyResistance:
        return 'Early insulin resistance';
      case HomaIrBand.significantResistance:
        return 'Significant insulin resistance';
    }
  }
}

/// Unit conversion helpers — most Moroccan/French-style lab reports give
/// glucose in g/L, US-style reports in mg/dL, and international ones in mmol/L.
class UnitConverter {
  UnitConverter._();

  static double glucoseToMgdl(double value, GlucoseUnit unit) {
    switch (unit) {
      case GlucoseUnit.mgdl:
        return value;
      case GlucoseUnit.mmoll:
        return value * 18.0182;
      case GlucoseUnit.gl:
        return value * 100;
    }
  }

  static double insulinToUiuml(double value, InsulinUnit unit) {
    switch (unit) {
      case InsulinUnit.uiuml:
        return value;
      case InsulinUnit.pmoll:
        return value / 6.945;
    }
  }
}
