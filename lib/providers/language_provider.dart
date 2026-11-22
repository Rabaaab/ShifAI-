import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// The app language, chosen in the header or in Profile. Stored on this
/// device only.
class LanguageProvider extends ChangeNotifier {
  static const _kLanguage = 'shifai_language';

  AppLanguage _language = AppLanguage.en;

  LanguageProvider() {
    _load();
  }

  AppLanguage get language => _language;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguage);
    final found = AppLanguage.values.where((l) => l.name == saved);
    if (found.isNotEmpty && found.first != _language) _apply(found.first);
  }

  void _apply(AppLanguage value) {
    _language = value;
    L10n.current = value;
    Intl.defaultLocale = value.intlLocale;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (value == _language) return;
    _apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value.name);
  }
}
