import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'lab_entry_form_screen.dart';

/// Camera-based OCR needs dart:io + Google ML Kit, neither available on web.
/// This stub keeps the web build compiling and points straight to manual entry.
/// Never actually reached on real devices — see platform_helper.dart — but
/// must still exist so the web compiler has something valid to resolve to.
class LabScanScreen extends StatelessWidget {
  const LabScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add lab result'.tr)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                size: 40,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera scanning is available on the Android/iOS app. '
                        'On the web, enter your values directly.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LabEntryFormScreen()),
                ),
                child: Text('Enter values manually'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
