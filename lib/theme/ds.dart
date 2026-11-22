import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/l10n.dart';

/// Design tokens of the agreed ShifAI design (navy and sky blue from the logo,
/// soft grey-white background, white rounded cards, Plus Jakarta Sans).
class DS {
  DS._();

  // Surfaces
  static const bgTop = Color(0xFFF4F6FA);
  static const bgBottom = Color(0xFFEAF1F8);
  static const card = Colors.white;
  static const field = Color(0xFFF1F5FA);
  static const hairline = Color(0xFFD6E2EE);
  static const divider = Color(0xFFEAF0F6);

  // Text
  static const ink = Color(0xFF0B1B33);
  static const muted = Color(0xFF5B6B80);
  static const iconMuted = Color(0xFF66758A);

  // Brand
  static const navy = Color(0xFF00307A);
  static const navy2 = Color(0xFF0A4A9E);
  static const sky = Color(0xFF9EC5E0);
  static const skyTint = Color(0xFFE3EEF8);
  static const onNavyMuted = Color(0xFFC9DEEE);

  // Status
  static const amber = Color(0xFFF5A524);
  static const amberTint = Color(0xFFFFF3D9);
  static const amberText = Color(0xFF8A5A00);
  static const green = Color(0xFF1FA971);
  static const greenTint = Color(0xFFE3F6EC);
  static const greenText = Color(0xFF0F7A4F);
  static const red = Color(0xFFE5484D);
  static const redTint = Color(0xFFFBE1E4);
  static const redText = Color(0xFF8F1D2C);
  static const emergency = Color(0xFFD7343A);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navy2],
  );

  static List<BoxShadow> cardShadow([double strength = 0.08]) => [
    BoxShadow(
      color: navy.withValues(alpha: strength),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: navy.withValues(alpha: 0.07),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: navy.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];

  static TextStyle text({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    // Tight tracking breaks the joined letters of Arabic script.
    letterSpacing: L10n.current == AppLanguage.ar ? null : letterSpacing,
  );
}
