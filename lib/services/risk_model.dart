import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../l10n/l10n.dart';
import '../models/user_profile.dart';

enum RiskBand { low, moderate, high }

extension RiskBandLabel on RiskBand {
  String get label {
    switch (this) {
      case RiskBand.low:
        return 'Low risk'.tr;
      case RiskBand.moderate:
        return 'Moderate risk'.tr;
      case RiskBand.high:
        return 'High risk'.tr;
    }
  }
}

/// Where an estimate comes from.
enum RiskBasis {
  /// Age, sex, BMI and waist only: no blood test.
  body,

  /// Body measurements plus glucose, HbA1c, triglycerides and HDL: no insulin
  /// test needed.
  labs,
}

/// One input that pushes the estimate up (or down), in standard deviations.
class RiskFactor {
  final String feature;
  final String label;
  final double contribution;
  const RiskFactor(this.feature, this.label, this.contribution);
}

class RiskAssessment {
  /// Estimated chance (0..1) that this person's HOMA-IR is 2.5 or higher.
  final double probability;
  final RiskBasis basis;

  /// Largest first. Taken from the logistic-regression half of the model,
  /// which is the one that can be read.
  final List<RiskFactor> factors;

  const RiskAssessment(
    this.probability, {
    this.basis = RiskBasis.body,
    this.factors = const [],
  });

  int get percent => (probability * 100).round();

  RiskBand get band {
    if (probability < 0.25) return RiskBand.low;
    if (probability < 0.50) return RiskBand.moderate;
    return RiskBand.high;
  }

  /// The inputs that raise the estimate the most (at most [max]).
  List<RiskFactor> topFactors({int max = 2, double minimum = 0.2}) => factors
      .where((f) => f.contribution >= minimum)
      .take(max)
      .toList(growable: false);
}

/// Blood values the lab model needs. Glucose, triglycerides and HDL in mg/dL.
class LabInputs {
  final double glucoseMgdl;
  final double hba1cPercent;
  final double triglyceridesMgdl;
  final double hdlMgdl;

  const LabInputs({
    required this.glucoseMgdl,
    required this.hba1cPercent,
    required this.triglyceridesMgdl,
    required this.hdlMgdl,
  });
}

class _Layer {
  final List<List<double>> w; // [in][out]
  final List<double> b;
  const _Layer(this.w, this.b);
}

/// One trained input set: a logistic regression and a small neural network
/// on the same standardised inputs. The app shows the mean of the two.
class ModelSet {
  final List<String> features;
  final List<double> mean;
  final List<double> scale;
  final List<double> lrCoef;
  final double lrIntercept;
  final List<_Layer> _layers;
  final double cvAuc;

  const ModelSet._(
    this.features,
    this.mean,
    this.scale,
    this.lrCoef,
    this.lrIntercept,
    this._layers,
    this.cvAuc,
  );

  factory ModelSet.fromJson(Map<String, dynamic> json) {
    List<double> nums(dynamic v) =>
        (v as List).map((e) => (e as num).toDouble()).toList();
    final layers = (json['mlp']['layers'] as List)
        .map(
          (l) => _Layer(
            (l['w'] as List).map<List<double>>(nums).toList(),
            nums(l['b']),
          ),
        )
        .toList();
    return ModelSet._(
      (json['features'] as List).cast<String>(),
      nums(json['mean']),
      nums(json['scale']),
      nums(json['lr']['coef']),
      (json['lr']['intercept'] as num).toDouble(),
      layers,
      ((json['metrics']['both']['auc']) as num).toDouble(),
    );
  }

  static double _sigmoid(double z) => 1 / (1 + math.exp(-z));

  List<double> _standardise(List<double> raw) => [
    for (var i = 0; i < raw.length; i++) (raw[i] - mean[i]) / scale[i],
  ];

  double logistic(List<double> raw) {
    final x = _standardise(raw);
    var z = lrIntercept;
    for (var i = 0; i < x.length; i++) {
      z += lrCoef[i] * x[i];
    }
    return _sigmoid(z);
  }

  double network(List<double> raw) {
    var a = _standardise(raw);
    for (var li = 0; li < _layers.length; li++) {
      final layer = _layers[li];
      final next = List<double>.from(layer.b);
      for (var i = 0; i < a.length; i++) {
        final row = layer.w[i];
        for (var j = 0; j < next.length; j++) {
          next[j] += a[i] * row[j];
        }
      }
      final last = li == _layers.length - 1;
      a = last ? next : [for (final v in next) v < 0 ? 0.0 : v];
    }
    return _sigmoid(a.first);
  }

  /// Average of the logistic regression and the neural network.
  double probability(List<double> raw) => (logistic(raw) + network(raw)) / 2;

  /// Contribution of each input to the logistic regression, in standard
  /// deviations of that input, largest first.
  List<MapEntry<String, double>> contributions(List<double> raw) {
    final x = _standardise(raw);
    final list = [
      for (var i = 0; i < x.length; i++)
        MapEntry(features[i], lrCoef[i] * x[i]),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

/// Models trained offline on NHANES (see ml/train_models.py) and evaluated
/// here on the phone. No network, no data leaves the phone.
class RiskModel {
  final Map<String, ModelSet> _sets;
  final Map<String, List<double>> _clip;
  final int trainedOn;
  final double prevalence;

  const RiskModel._(this._sets, this._clip, this.trainedOn, this.prevalence);

  factory RiskModel.fromJson(Map<String, dynamic> json) {
    final sets = (json['sets'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, ModelSet.fromJson(v as Map<String, dynamic>)),
    );
    final clip = (json['clip'] as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()),
    );
    return RiskModel._(
      sets,
      clip,
      (json['n'] as num).toInt(),
      (json['prevalence'] as num).toDouble(),
    );
  }

  static Future<RiskModel> loadAsset() async {
    final raw = await rootBundle.loadString('assets/ml/risk_model.json');
    return RiskModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  ModelSet setFor(RiskBasis basis) =>
      _sets[basis == RiskBasis.body ? 'basic' : 'lab']!;

  /// Cross-validated AUC of the shown (averaged) model for [basis].
  double aucFor(RiskBasis basis) => setFor(basis).cvAuc;

  static const _labels = {
    'age': 'Age',
    'female': 'Sex',
    'bmi': 'Body mass index',
    'whtr': 'Waist compared with height',
    'glucose': 'Fasting glucose',
    'hba1c': 'HbA1c',
    'trig': 'Triglycerides',
    'hdl': 'HDL cholesterol',
  };

  /// Inputs are clamped to the range the model has seen, so an odd value can't
  /// push the estimate outside what it was trained on.
  double _clamped(String feature, double value) {
    final range = _clip[feature];
    if (range == null) return value;
    return value.clamp(range[0], range[1]);
  }

  RiskAssessment _assess(RiskBasis basis, Map<String, double> raw) {
    final set = setFor(basis);
    final x = [
      for (final f in set.features)
        f == 'female' ? raw[f]! : _clamped(f, raw[f]!),
    ];
    return RiskAssessment(
      set.probability(x),
      basis: basis,
      factors: [
        for (final c in set.contributions(x))
          RiskFactor(c.key, (_labels[c.key] ?? c.key).tr, c.value),
      ],
    );
  }

  Map<String, double> _body(UserProfile p) => {
    'age': p.age.toDouble(),
    'female': p.female ? 1.0 : 0.0,
    'bmi': p.bmi,
    'whtr': p.waistToHeight,
  };

  /// Estimate from body measurements only.
  RiskAssessment assessBody(UserProfile p) => _assess(RiskBasis.body, _body(p));

  /// Estimate from body measurements and routine blood values (no insulin).
  RiskAssessment assessLabs(UserProfile p, LabInputs labs) =>
      _assess(RiskBasis.labs, {
        ..._body(p),
        'glucose': labs.glucoseMgdl,
        'hba1c': labs.hba1cPercent,
        'trig': labs.triglyceridesMgdl,
        'hdl': labs.hdlMgdl,
      });

  /// Kept for older call sites.
  RiskAssessment assess(UserProfile p) => assessBody(p);

  /// Probability from raw inputs, for tests.
  double probabilityFor(RiskBasis basis, Map<String, double> raw) =>
      _assess(basis, raw).probability;
}
