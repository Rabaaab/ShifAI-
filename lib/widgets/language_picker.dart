import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/language_provider.dart';
import '../theme/ds.dart';

/// Bottom sheet to choose the app language.
Future<void> pickLanguage(BuildContext context) async {
  final provider = context.read<LanguageProvider>();
  final chosen = await showModalBottomSheet<AppLanguage>(
    context: context,
    backgroundColor: DS.bgTop,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _LanguageSheet(selected: provider.language),
  );
  if (chosen != null) await provider.setLanguage(chosen);
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.selected});
  final AppLanguage selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language'.tr,
            style: DS.text(size: 24, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final lang in AppLanguage.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                lang.nativeName,
                // Each name is written in its own direction.
                textDirection: lang == AppLanguage.ar
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: DS.text(
                  size: 17,
                  weight: lang == selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              trailing: lang == selected
                  ? const Icon(Icons.check_rounded, color: DS.navy)
                  : null,
              onTap: () => Navigator.pop(context, lang),
            ),
        ],
      ),
    ),
  );
}

/// Round header button showing the current language; opens the picker.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    return Semantics(
      button: true,
      label: '${'Language'.tr}: ${lang.nativeName}',
      child: GestureDetector(
        onTap: () => pickLanguage(context),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: DS.navy.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 22, color: DS.ink),
              const SizedBox(width: 6),
              Text(
                lang.shortLabel,
                style: DS.text(size: 14.5, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
