import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import '../widgets/language_picker.dart';
import 'auth_screen.dart';

/// First screen for a signed-out user.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _open(BuildContext context, AuthStart start) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AuthScreen(start: start)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Image.asset(
                          'assets/images/shifai_logo.png',
                          width: 168,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          semanticLabel: 'ShifAI',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const LanguageButton(),
                  ],
                ),
                const SizedBox(height: 30),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Know your\n'.tr,
                        style: DS.text(size: 38, weight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: 'insulin health.'.tr,
                        style: DS.text(size: 38, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    height: 1.12,
                    letterSpacing: L10n.current == AppLanguage.ar ? 0 : -0.76,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Scan a lab report. Watch your trend.'.tr,
                  style: DS.text(
                    size: 17,
                    weight: FontWeight.w500,
                    color: DS.muted,
                    height: 1.5,
                  ),
                ),
                const Expanded(child: _Illustration()),
                DsPrimaryButton(
                  label: 'Get started'.tr,
                  onPressed: () => _open(context, AuthStart.createAccount),
                ),
                const SizedBox(height: 6),
                DsTextAction(
                  'I already have an account'.tr,
                  onPressed: () => _open(context, AuthStart.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFCFE3F2), Color(0x00CFE3F2)],
                      stops: [0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: math.min(34, h * 0.1),
              child: Transform.rotate(
                angle: -3 * math.pi / 180,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: DS.navy.withValues(alpha: 0.14),
                        blurRadius: 50,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'HOMA-IR',
                              style: DS.text(
                                size: 14,
                                weight: FontWeight.w600,
                                color: DS.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: DsPill(
                              'Borderline'.tr,
                              background: DS.amberTint,
                              foreground: DS.amberText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '2.1',
                        style: DS.text(
                          size: 52,
                          weight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: CustomPaint(painter: _SparkPainter()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: math.min(170, h * 0.45),
              child: Transform.rotate(
                angle: 3 * math.pi / 180,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: DS.navy,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: DS.navy.withValues(alpha: 0.28),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.document_scanner_outlined,
                        size: 26,
                        color: DS.sky,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan report'.tr,
                        style: DS.text(
                          size: 16,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Read in seconds'.tr,
                        style: DS.text(
                          size: 13,
                          weight: FontWeight.w500,
                          color: const Color(0xFFB7D3E8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.2)
      ..cubicTo(w * 0.15, h * 0.22, w * 0.2, h * 0.45, w * 0.34, h * 0.5)
      ..cubicTo(w * 0.5, h * 0.62, w * 0.62, h * 0.72, w * 0.75, h * 0.78)
      ..cubicTo(w * 0.88, h * 0.84, w * 0.95, h * 0.9, w, h * 0.92);
    canvas.drawPath(
      path,
      Paint()
        ..color = DS.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(w - 4, h * 0.92), 6, Paint()..color = DS.navy);
    canvas.drawCircle(Offset(w - 4, h * 0.92), 3, Paint()..color = DS.sky);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
