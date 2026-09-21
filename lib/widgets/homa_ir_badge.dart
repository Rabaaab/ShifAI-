import 'package:flutter/material.dart';
import '../models/lab_record.dart';
import '../theme/app_colors.dart';

class HomaIrBadge extends StatelessWidget {
  final double homaIr;
  final HomaIrBand band;
  final double size;

  const HomaIrBadge({
    super.key,
    required this.homaIr,
    required this.band,
    this.size = 96,
  });

  Color get _color {
    switch (band) {
      case HomaIrBand.optimal:
        return AppColors.safe;
      case HomaIrBand.normal:
        return AppColors.accentBlue;
      case HomaIrBand.earlyResistance:
        return AppColors.warning;
      case HomaIrBand.significantResistance:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.12),
            border: Border.all(color: _color, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(
            homaIr.toStringAsFixed(2),
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          band.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, color: _color, fontSize: 13),
        ),
      ],
    );
  }
}
