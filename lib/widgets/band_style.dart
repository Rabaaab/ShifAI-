import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';
import '../theme/ds.dart';
import 'ds_widgets.dart';

/// Colors of a HOMA-IR band in the agreed design:
/// green (optimal, normal), amber (borderline), red (insulin resistance likely).
Color bandColor(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return DS.green;
    case HomaIrBand.earlyResistance:
      return DS.amber;
    case HomaIrBand.significantResistance:
      return DS.red;
  }
}

Color bandBackground(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return DS.greenTint;
    case HomaIrBand.earlyResistance:
      return DS.amberTint;
    case HomaIrBand.significantResistance:
      return DS.redTint;
  }
}

Color bandTextColor(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return DS.greenText;
    case HomaIrBand.earlyResistance:
      return DS.amberText;
    case HomaIrBand.significantResistance:
      return DS.redText;
  }
}

/// Plain-language reading of a HOMA-IR band. Never a diagnosis.
String bandExplanation(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
      return 'Your body is handling blood glucose with very little insulin. '
              'Keep up the habits that got you here.'
          .tr;
    case HomaIrBand.normal:
      return 'Your result is within the usual range. Regular walks and '
              'balanced meals help keep it there.'
          .tr;
    case HomaIrBand.earlyResistance:
      return 'Your body is producing more insulin than usual to manage blood '
              'glucose. This stage often responds well to everyday lifestyle '
              'changes.'
          .tr;
    case HomaIrBand.significantResistance:
      return 'Your body needs a lot of insulin to manage blood glucose. This '
              'is worth discussing with your doctor. ShifAI cannot diagnose you.'
          .tr;
  }
}

class BandChip extends StatelessWidget {
  final HomaIrBand band;
  final double size;
  const BandChip({super.key, required this.band, this.size = 13});

  @override
  Widget build(BuildContext context) => DsPill(
    band.label,
    background: bandBackground(band),
    foreground: bandTextColor(band),
    size: size,
  );
}
