import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

/// Web: reading a prescription needs the phone camera and Google ML Kit.
class PrescriptionScanScreen extends StatelessWidget {
  const PrescriptionScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DsBackButton(),
                const SizedBox(height: 26),
                const DsTitle('Scan your', 'prescription', size: 36),
                const SizedBox(height: 14),
                Text(
                  'Reading a prescription from a photo works in the Android '
                          'and iPhone app. On the web, add your medicine by hand.'
                      .tr,
                  style: DS.text(
                    size: 15.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
