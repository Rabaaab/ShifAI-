/// App languages and string lookup.
///
/// The English text in the code is the key: `'Search'.tr` returns the
/// translation for the current language, or the English text when there is
/// none yet. Text with values uses `{name}` placeholders:
/// `'Welcome, {name}'.trf({'name': name})`.
library;

import 'package:flutter/widgets.dart';

import 'strings_ar.dart';
import 'strings_fr.dart';
import 'strings_zgh.dart';

enum AppLanguage { en, fr, ar, zgh }

extension AppLanguageX on AppLanguage {
  /// The language's name in that language, as shown in the picker.
  String get nativeName => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.fr => 'Français',
    AppLanguage.ar => 'العربية',
    AppLanguage.zgh => 'Tamaziɣt',
  };

  /// Short label for the header button.
  String get shortLabel => switch (this) {
    AppLanguage.en => 'EN',
    AppLanguage.fr => 'FR',
    AppLanguage.ar => 'ع',
    AppLanguage.zgh => 'ⵣ',
  };

  /// Locale for Flutter's own widgets (date picker, text fields...). Flutter
  /// has no Tamazight translations, so French is used for those.
  Locale get materialLocale => switch (this) {
    AppLanguage.en => const Locale('en'),
    AppLanguage.fr => const Locale('fr'),
    AppLanguage.ar => const Locale('ar'),
    AppLanguage.zgh => const Locale('fr'),
  };

  /// Locale for dates and numbers (intl has no Tamazight data either).
  String get intlLocale => switch (this) {
    AppLanguage.en => 'en',
    AppLanguage.fr => 'fr',
    AppLanguage.ar => 'ar',
    AppLanguage.zgh => 'fr',
  };
}

class L10n {
  L10n._();

  /// Set by LanguageProvider. The whole app is rebuilt when it changes.
  static AppLanguage current = AppLanguage.en;

  static const _tables = <AppLanguage, Map<String, String>>{
    AppLanguage.fr: stringsFr,
    AppLanguage.ar: stringsAr,
    AppLanguage.zgh: stringsZgh,
  };

  static String lookup(String english) => _tables[current]?[english] ?? english;
}

extension Tr on String {
  /// This English text in the current language.
  String get tr => L10n.lookup(this);

  /// Like [tr], then fills the `{name}` placeholders.
  String trf(Map<String, Object?> args) {
    var out = L10n.lookup(this);
    args.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }
}
