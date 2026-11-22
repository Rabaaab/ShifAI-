import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/language_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/risk_model.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import '../widgets/language_picker.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(what)));
  }

  void _privacy(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Your privacy'.tr, style: DS.text(weight: FontWeight.w800)),
        content: Text(
          auth.isSignedIn
              ? 'Your confirmed lab values sync to your Supabase account and '
                        'stay cached on this device for offline use. Photos are '
                        'read on your phone and are not uploaded. Your body '
                        'measurements stay on this device.'
                    .tr
              : 'No account is active. Results and measurements stay on this '
                        'device and are not uploaded. Photos are read on your '
                        'phone.'
                    .tr,
          style: DS.text(size: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _textSize(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DS.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Text size'.tr,
                style: DS.text(size: 24, weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final entry in SettingsProvider.textSizes.entries)
                Semantics(
                  button: true,
                  selected: entry.key == settings.textScale,
                  label: entry.value.tr,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      settings.setTextScale(entry.key);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value.tr,
                              style: DS.text(
                                size: 16.5 * entry.key,
                                weight: entry.key == settings.textScale
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: entry.key == settings.textScale
                                    ? DS.navy
                                    : DS.ink,
                              ),
                            ),
                          ),
                          if (entry.key == settings.textScale)
                            const Icon(Icons.check_rounded, color: DS.navy),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await context.read<AuthProvider>().signOut();
    } on AuthException catch (error) {
      if (context.mounted) _soon(context, error.message);
    } on ClientException {
      if (context.mounted) {
        _soon(context, 'Could not reach Supabase. Try again when online.'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final labs = context.watch<LabRecordsProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final p = profileProvider.profile;
    final assessment = profileProvider.assessment;

    final display = auth.displayName == 'ShifAI member'
        ? ''
        : auth.displayName;
    final initial = (display.isNotEmpty ? display : (auth.email ?? 'S'))
        .characters
        .first
        .toUpperCase();
    final name = auth.isSignedIn
        ? (display.isNotEmpty ? display : 'ShifAI member'.tr)
        : 'This device'.tr;

    return DsBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            const DsTitle('Your', 'profile', size: 38),
            const SizedBox(height: 22),
            DsCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: DS.navy,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: DS.text(
                        size: 26,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DS.text(
                            size: 20,
                            weight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.email ?? 'Not signed in'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DS.text(
                            size: 14,
                            weight: FontWeight.w500,
                            color: DS.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (auth.isSignedIn)
                    DsPill(
                      labs.syncError == null ? 'Synced'.tr : 'Sync paused'.tr,
                      background: labs.syncError == null
                          ? DS.greenTint
                          : DS.amberTint,
                      foreground: labs.syncError == null
                          ? DS.greenText
                          : DS.amberText,
                      dot: labs.syncError == null ? DS.green : DS.amber,
                      size: 12.5,
                    )
                  else
                    DsPill(
                      'On device'.tr,
                      background: DS.skyTint,
                      foreground: DS.navy,
                      size: 12.5,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            DsSectionHeader(
              'My measurements'.tr,
              action: p == null ? 'Add'.tr : 'Edit'.tr,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
              ),
            ),
            if (p == null)
              DsCard(
                radius: 24,
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Add your age, height, weight and waist to get a risk '
                          'estimate. No blood test needed.'
                      .tr,
                  style: DS.text(
                    size: 14.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                    height: 1.5,
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _Tile('Age'.tr, '${p.age}'),
                  _Tile('Sex'.tr, p.female ? 'Female'.tr : 'Male'.tr),
                  _Tile('Height'.tr, p.heightCm.toStringAsFixed(0), unit: 'cm'),
                  _Tile('Weight'.tr, p.weightKg.toStringAsFixed(0), unit: 'kg'),
                ],
              ),
            if (assessment != null) ...[
              const SizedBox(height: 12),
              _RiskRow(assessment: assessment),
            ],
            const SizedBox(height: 22),
            DsCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.language_rounded,
                    label: 'Language'.tr,
                    value: context
                        .watch<LanguageProvider>()
                        .language
                        .nativeName,
                    onTap: () => pickLanguage(context),
                  ),
                  const Divider(height: 1, color: DS.divider),
                  _SettingRow(
                    glyph: 'Aa',
                    label: 'Text size'.tr,
                    value: context.watch<SettingsProvider>().textSizeLabel.tr,
                    onTap: () => _textSize(context),
                  ),
                  const Divider(height: 1, color: DS.divider),
                  _SettingRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy'.tr,
                    onTap: () => _privacy(context, auth),
                  ),
                  if (auth.isSignedIn) ...[
                    const Divider(height: 1, color: DS.divider),
                    _SettingRow(
                      icon: Icons.file_download_outlined,
                      label: 'Import local-only results'.tr,
                      onTap: () => _importLocalRecords(context),
                    ),
                  ],
                ],
              ),
            ),
            if (auth.isSignedIn) ...[
              const SizedBox(height: 22),
              DsOutlineButton(
                label: auth.busy ? 'Signing out…'.tr : 'Sign out'.tr,
                icon: Icons.logout_rounded,
                color: const Color(0xFFB3261E),
                iconColor: const Color(0xFFB3261E),
                onPressed: auth.busy ? null : () => _signOut(context),
              ),
            ],
            const SizedBox(height: 18),
            Center(
              child: Text(
                'ShifAI is a screening tool, not a diagnosis.\n'
                        'Please review your results with your doctor.'
                    .tr,
                textAlign: TextAlign.center,
                style: DS.text(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLocalRecords(BuildContext context) async {
    final provider = context.read<LabRecordsProvider>();
    final count = await provider.guestRecordCount();
    if (!context.mounted) return;
    if (count == 0) {
      _soon(context, 'There are no local-only results to import.'.tr);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Import local results?'.tr,
          style: DS.text(weight: FontWeight.w800),
        ),
        content: Text(
          (count == 1
                  ? '1 local result will be copied to this signed-in account. '
                        'Existing account records will not be replaced.'
                  : '{count} local results will be copied to this signed-in '
                        'account. Existing account records will not be replaced.')
              .trf({'count': count}),
          style: DS.text(size: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Import'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final imported = await provider.importGuestRecordsToAccount();
    if (context.mounted) {
      _soon(
        context,
        imported == 0
            ? 'Those local results are already in this account.'.tr
            : provider.syncError == null
            ? (imported == 1
                      ? '1 result synced to this account.'
                      : '{count} results synced to this account.')
                  .trf({'count': imported})
            : (imported == 1
                      ? '1 result saved locally; cloud sync will retry.'
                      : '{count} results saved locally; cloud sync will retry.')
                  .trf({'count': imported}),
      );
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: DS.softShadow,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DS.text(size: 13, weight: FontWeight.w600, color: DS.muted),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: DS.text(
                  size: 21,
                  weight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: DS.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Estimated risk from body measurements (the on-device logistic model).
class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.assessment});
  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final band = assessment.band;
    final color = switch (band) {
      RiskBand.low => DS.green,
      RiskBand.moderate => DS.amber,
      RiskBand.high => DS.red,
    };
    return DsCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated risk'.tr,
                  style: DS.text(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  switch (band) {
                    RiskBand.low => 'Low',
                    RiskBand.moderate => 'Moderate',
                    RiskBand.high => 'High',
                  }.tr,
                  style: DS.text(size: 19, weight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: assessment.probability.clamp(0.02, 1.0),
                    minHeight: 8,
                    color: color,
                    backgroundColor: DS.skyTint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Text(
            '${assessment.percent}%',
            style: DS.text(
              size: 30,
              weight: FontWeight.w800,
              color: DS.navy,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    this.icon,
    this.glyph,
    required this.label,
    this.value,
    required this.onTap,
  });
  final IconData? icon;
  final String? glyph;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            if (icon != null)
              DsIconBadge(icon: icon!, size: 42)
            else
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DS.skyTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  glyph!,
                  style: DS.text(
                    size: 15,
                    weight: FontWeight.w800,
                    color: DS.navy,
                  ),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: DS.text(size: 16, weight: FontWeight.w600),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value!,
                  style: DS.text(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: DS.iconMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
