import 'package:flutter/material.dart';

/// ShifAI brand palette.
/// Blue identity (navy/accentBlue) kept from the logo & branding work;
/// warmth and calm borrowed from the WanisAI reference — cream backgrounds
/// instead of heavy blue tinting, a muted button blue, and contextual
/// banner colors (info/warning/safe) instead of one color doing everything.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF1F4E79);
  static const Color accentBlue = Color(0xFF4A90C2);

  // Muted, calmer blue for primary buttons — softer than accentBlue.
  static const Color buttonBlue = Color(0xFF5B84A8);

  // Warm cream, replaces the old pastel-blue-tinted background.
  static const Color cream = Color(0xFFFAF6EE);
  static const Color creamCard = Color(0xFFFFFFFF);

  static const Color pastel = Color(0xFFDCEEFA);
  static const Color pastelBorder = Color(0xFFE4DCC8);

  static const Color text = Color(0xFF33342E);
  static const Color gray = Color(0xFF767569);

  // Contextual banner colors, matching WanisAI's "safety first" / "you are safe" pattern.
  static const Color warningBg = Color(0xFFFBF1D9);
  static const Color warningText = Color(0xFFB07C2C);
  static const Color safeBg = Color(0xFFE4F1E6);
  static const Color safeText = Color(0xFF3E7A52);
  static const Color dangerBg = Color(0xFFF8E7E5);
  static const Color dangerText = Color(0xFFB0453A);

  static const Color warning = Color(0xFFE0A458);
  static const Color danger = Color(0xFFD9695F);
  static const Color safe = Color(0xFF5FA777);

  // Warm accent, used sparingly (small icon touches) like WanisAI's gold mark.
  static const Color gold = Color(0xFFC9A24B);
}
