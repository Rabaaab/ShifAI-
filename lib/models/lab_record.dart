import '../l10n/l10n.dart';

enum GlucoseUnit { mgdl, mmoll, gl }

enum InsulinUnit { uiuml, pmoll }

/// Unit printed next to triglycerides or HDL cholesterol.
enum LipidUnit { gl, mmoll, mgdl }

class LabRecord {
  final String id;
  final DateTime date;
  final double? fastingGlucoseMgdl; // stored normalized to mg/dL
  final double? fastingInsulinUiuml; // stored normalized to µIU/mL
  final double? hba1cPercent;
  final double? triglyceridesMgdl; // stored normalized to mg/dL
  final double? hdlMgdl; // stored normalized to mg/dL
  final String? notes;
  final List<LabMarker> otherMarkers;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  LabRecord({
    required this.id,
    required this.date,
    this.fastingGlucoseMgdl,
    this.fastingInsulinUiuml,
    this.hba1cPercent,
    this.triglyceridesMgdl,
    this.hdlMgdl,
    this.notes,
    this.otherMarkers = const [],
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

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
    if (value < 2.5) return HomaIrBand.earlyResistance;
    return HomaIrBand.significantResistance;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'fastingGlucoseMgdl': fastingGlucoseMgdl,
    'fastingInsulinUiuml': fastingInsulinUiuml,
    'hba1cPercent': hba1cPercent,
    'triglyceridesMgdl': triglyceridesMgdl,
    'hdlMgdl': hdlMgdl,
    'notes': notes,
    'otherMarkers': otherMarkers.map((marker) => marker.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory LabRecord.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final rawMarkers = json['otherMarkers'] as List<dynamic>? ?? const [];
    return LabRecord(
      id: json['id'] as String,
      date: date,
      fastingGlucoseMgdl: (json['fastingGlucoseMgdl'] as num?)?.toDouble(),
      fastingInsulinUiuml: (json['fastingInsulinUiuml'] as num?)?.toDouble(),
      hba1cPercent: (json['hba1cPercent'] as num?)?.toDouble(),
      triglyceridesMgdl: (json['triglyceridesMgdl'] as num?)?.toDouble(),
      hdlMgdl: (json['hdlMgdl'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      otherMarkers: rawMarkers
          .map((marker) => LabMarker.fromJson(marker as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? date,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toCloudJson(String userId) => {
    'id': id,
    'user_id': userId,
    'report_date': date.toIso8601String().substring(0, 10),
    'fasting_glucose_mg_dl': fastingGlucoseMgdl,
    'fasting_insulin_uiu_ml': fastingInsulinUiuml,
    'hba1c_percent': hba1cPercent,
    if (triglyceridesMgdl != null) 'triglycerides_mg_dl': triglyceridesMgdl,
    if (hdlMgdl != null) 'hdl_mg_dl': hdlMgdl,
    'other_markers': otherMarkers.map((marker) => marker.toJson()).toList(),
    'notes': notes,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  factory LabRecord.fromCloudJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['report_date'] as String);
    final rawMarkers = json['other_markers'] as List<dynamic>? ?? const [];
    return LabRecord(
      id: json['id'] as String,
      date: date,
      fastingGlucoseMgdl: (json['fasting_glucose_mg_dl'] as num?)?.toDouble(),
      fastingInsulinUiuml: (json['fasting_insulin_uiu_ml'] as num?)?.toDouble(),
      hba1cPercent: (json['hba1c_percent'] as num?)?.toDouble(),
      triglyceridesMgdl: (json['triglycerides_mg_dl'] as num?)?.toDouble(),
      hdlMgdl: (json['hdl_mg_dl'] as num?)?.toDouble(),
      otherMarkers: rawMarkers
          .map((marker) => LabMarker.fromJson(marker as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? date,
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }
}

class LabMarker {
  const LabMarker({
    required this.name,
    required this.value,
    required this.unit,
  });

  final String name;
  final double value;
  final String unit;

  Map<String, dynamic> toJson() => {'name': name, 'value': value, 'unit': unit};

  factory LabMarker.fromJson(Map<String, dynamic> json) => LabMarker(
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
    unit: json['unit'] as String,
  );
}

enum HomaIrBand { optimal, normal, earlyResistance, significantResistance }

extension HomaIrBandLabel on HomaIrBand {
  String get label {
    switch (this) {
      case HomaIrBand.optimal:
        return 'Optimal'.tr;
      case HomaIrBand.normal:
        return 'Normal'.tr;
      case HomaIrBand.earlyResistance:
        return 'Borderline'.tr;
      case HomaIrBand.significantResistance:
        return 'Insulin resistance likely'.tr;
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

  /// Triglycerides to mg/dL (g/L x 100, mmol/L x 88.57).
  static double triglyceridesToMgdl(double value, LipidUnit unit) {
    switch (unit) {
      case LipidUnit.mgdl:
        return value;
      case LipidUnit.mmoll:
        return value * 88.57;
      case LipidUnit.gl:
        return value * 100;
    }
  }

  /// HDL cholesterol to mg/dL (g/L x 100, mmol/L x 38.67).
  static double hdlToMgdl(double value, LipidUnit unit) {
    switch (unit) {
      case LipidUnit.mgdl:
        return value;
      case LipidUnit.mmoll:
        return value * 38.67;
      case LipidUnit.gl:
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
