import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifai/l10n/l10n.dart';
import 'package:shifai/models/lab_record.dart';
import 'package:shifai/models/doctor.dart';
import 'package:shifai/models/user_profile.dart';
import 'package:shifai/providers/activity_provider.dart';
import 'package:shifai/providers/appointment_provider.dart';
import 'package:shifai/providers/auth_provider.dart';
import 'package:shifai/providers/coaching_provider.dart';
import 'package:shifai/providers/lab_records_provider.dart';
import 'package:shifai/providers/language_provider.dart';
import 'package:shifai/providers/medicine_provider.dart';
import 'package:shifai/providers/nav_provider.dart';
import 'package:shifai/providers/profile_provider.dart';
import 'package:shifai/providers/settings_provider.dart';
import 'package:shifai/providers/skin_check_provider.dart';
import 'package:shifai/screens/app_shell.dart';
import 'package:shifai/screens/book_screen.dart';
import 'package:shifai/screens/auth_screen.dart';
import 'package:shifai/screens/emergency_screen.dart';
import 'package:shifai/screens/find_doctor_screen.dart';
import 'package:shifai/screens/lab_entry_form_screen.dart';
import 'package:shifai/screens/lab_scan_screen.dart';
import 'package:shifai/screens/medicine_screen.dart';
import 'package:shifai/screens/notifications_screen.dart';
import 'package:shifai/screens/profile_form_screen.dart';
import 'package:shifai/screens/result_screen.dart';
import 'package:shifai/screens/search_screen.dart';
import 'package:shifai/screens/shortcuts_screen.dart';
import 'package:shifai/screens/skin_check_screen.dart';
import 'package:shifai/screens/wellness_screen.dart';
import 'package:shifai/screens/welcome_screen.dart';
import 'package:shifai/services/risk_model.dart';
import 'package:shifai/theme/app_theme.dart';
import 'package:shifai/widgets/ds_widgets.dart';
import 'package:shifai/widgets/language_picker.dart';

final testModel = RiskModel.fromJson(
  jsonDecode(File('assets/ml/risk_model.json').readAsStringSync())
      as Map<String, dynamic>,
);

Widget _app(Widget home, {AuthProvider? auth}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => auth ?? AuthProvider()),
    ChangeNotifierProvider(create: (_) => LabRecordsProvider()),
    ChangeNotifierProvider(create: (_) => CoachingProvider()),
    ChangeNotifierProvider(create: (_) => NavProvider()),
    ChangeNotifierProvider(create: (_) => ProfileProvider(model: testModel)),
    ChangeNotifierProvider(create: (_) => AppointmentProvider()),
    ChangeNotifierProvider(create: (_) => MedicineProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => ActivityProvider()),
    ChangeNotifierProvider(create: (_) => SkinCheckProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
  ],
  child: MaterialApp(theme: AppTheme.light(), home: home),
);

void phone(WidgetTester tester, {double w = 390, double h = 1300}) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The test font (Ahem) is about twice as wide as a real font, so scale the
  // text to make widths realistic.
  tester.platformDispatcher.textScaleFactorTestValue = 0.55;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> openAppShell(WidgetTester tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const AppShell()));
    await tester.pumpAndSettle();
  }

  Future<void> enterResult(
    WidgetTester tester, {
    required String glucose,
    required String insulin,
  }) async {
    // The bar's Scan opens manual entry off a phone.
    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), glucose);
    await tester.enterText(find.byType(TextFormField).at(1), insulin);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
  }

  testWidgets('first visit shows the scan banner and the four-item bar', (
    tester,
  ) async {
    await openAppShell(tester);

    expect(find.text('Scan your first lab report'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    // Trends is both a quick action and a bar item.
    expect(find.text('Trends'), findsNWidgets(2));
    // Scan is both a quick action and a bar item.
    expect(find.text('Scan'), findsNWidgets(3));
    // No doctor shortcuts before a doctor is booked.
    expect(find.text('Medicine'), findsNothing);
    expect(find.text('Emergency'), findsNothing);
    expect(find.text('Upcoming appointment'), findsNothing);
  });

  testWidgets('home lays out on a narrow phone', (tester) async {
    await tester.pumpWidget(_app(const AppShell()));
    phone(tester, w: 350, h: 900);
    await tester.pumpAndSettle();
    expect(find.text('Scan your first lab report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trends and profile tabs open', (tester) async {
    await openAppShell(tester);

    await tester.tap(find.text('Trends').last);
    await tester.pumpAndSettle();
    expect(find.text('No results yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My measurements'), findsOneWidget);
    expect(find.text('Not signed in'), findsOneWidget);
  });

  testWidgets('a normal result shows HOMA-IR and no doctor suggestion', (
    tester,
  ) async {
    await openAppShell(tester);

    // glucose 0.95 g/L = 95 mg/dL, insulin 9 uIU/mL -> 95 * 9 / 405 = 2.11
    await enterResult(tester, glucose: '0.95', insulin: '9');

    expect(find.text('2.11'), findsOneWidget);
    expect(find.text('Borderline'), findsOneWidget);
    expect(find.text('See a doctor about this result'), findsNothing);

    await tester.tap(find.text('Save and see my trends'));
    await tester.pumpAndSettle();
    expect(find.text('Over time'), findsOneWidget);
    expect(find.text('2.11'), findsWidgets);
  });

  testWidgets('a high result suggests a doctor and booking unlocks Home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'shifai_city': 'Fès'});
    await openAppShell(tester);

    // 112 mg/dL x 12.5 / 405 = 3.46: insulin resistance likely
    await enterResult(tester, glucose: '1.12', insulin: '12.5');
    expect(find.text('Insulin resistance likely'), findsOneWidget);
    expect(find.text('See a doctor about this result'), findsOneWidget);

    await tester.tap(find.text('Find a doctor'));
    await tester.pumpAndSettle();
    expect(find.text('In Fès'), findsOneWidget);

    await tester.tap(find.text('Book').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
    await tester.ensureVisible(find.text('Book now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book now'));
    await tester.pumpAndSettle();

    // Back on Home, now following a doctor.
    expect(find.text('Upcoming appointment'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Latest result'), findsOneWidget);
  });

  testWidgets('measurements give a risk estimate on the profile', (
    tester,
  ) async {
    await openAppShell(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // 45-year-old woman, BMI 27.5, waist-to-height 0.55
    await tester.enterText(find.byType(TextFormField).at(0), '45');
    await tester.enterText(find.byType(TextFormField).at(1), '165');
    await tester.enterText(find.byType(TextFormField).at(2), '74.9');
    await tester.enterText(find.byType(TextFormField).at(3), '90.75');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final expected = testModel.assessBody(
      const UserProfile(
        age: 45,
        female: true,
        heightCm: 165,
        weightKg: 74.9,
        waistCm: 90.75,
      ),
    );
    expect(find.text('${expected.percent}%'), findsOneWidget);
    expect(
      find.text(expected.band.label.replaceAll(' risk', '')),
      findsOneWidget,
    );
  });

  testWidgets('measurements form rejects an out-of-range height', (
    tester,
  ) async {
    await openAppShell(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '45');
    await tester.enterText(find.byType(TextFormField).at(1), '16');
    await tester.enterText(find.byType(TextFormField).at(2), '70');
    await tester.enterText(find.byType(TextFormField).at(3), '80');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enter 120'), findsOneWidget);
  });

  testWidgets('scan screen lays out without errors', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LabScanScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Fit the page in the frame'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medicine can be marked as taken', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const MedicineScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 taken'), findsOneWidget);
    await tester.tap(find.text('Mark as taken'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 taken'), findsOneWidget);
  });

  testWidgets('doctors depend on the chosen city', (tester) async {
    SharedPreferences.setMockInitialValues({'shifai_city': 'Fès'});
    phone(tester);
    await tester.pumpWidget(_app(const FindDoctorScreen()));
    await tester.pumpAndSettle();
    expect(find.text('In Fès'), findsOneWidget);
    expect(find.text('Book'), findsNWidgets(3));
  });

  testWidgets('a city with no listed doctors says so', (tester) async {
    SharedPreferences.setMockInitialValues({'shifai_city': 'Agadir'});
    phone(tester);
    await tester.pumpWidget(_app(const FindDoctorScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('listed in Agadir'), findsOneWidget);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('logging activity fills the weekly goal', (tester) async {
    phone(tester, h: 2500);
    await tester.pumpWidget(_app(const WellnessScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Build your plate'), findsOneWidget);

    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 150 min'), findsOneWidget);
    await tester.tap(find.text('+20 min'));
    await tester.pumpAndSettle();
    expect(find.text('20 of 150 min'), findsOneWidget);
  });

  testWidgets('the skin check scores the risk questions', (tester) async {
    SharedPreferences.setMockInitialValues({
      'shifai_profile': '{"age":55,"female":false,"heightCm":170,"weightKg":95,"waistCm":105}',
    });
    phone(tester, h: 3000);
    await tester.pumpWidget(_app(const SkinCheckScreen()));
    await tester.pumpAndSettle();

    // Order of the Yes/No cards: patches, tags, family, pressure, active.
    await tester.tap(find.text('No').at(0));
    await tester.tap(find.text('No').at(1));
    await tester.tap(find.text('Yes').at(2));
    await tester.tap(find.text('Yes').at(3));
    await tester.tap(find.text('No').at(4));
    await tester.pumpAndSettle();

    // age 55 = 2, male = 1, BMI 32.9 = 2, family 1, pressure 1, not active 1
    expect(find.text('Risk score 8'), findsOneWidget);
    expect(find.text('Scan a lab report'), findsOneWidget);
  });

  testWidgets('search finds features and food', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const SearchScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'walk');
    await tester.pumpAndSettle();
    expect(find.text('Eat and move'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'couscous');
    await tester.pumpAndSettle();
    expect(find.text('Couscous, rice, pasta'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No match'), findsOneWidget);
  });

  testWidgets('notifications reflect the app and clear the badge', (
    tester,
  ) async {
    await openAppShell(tester);
    // First visit: the bell shows a count (1, or 2 when it is late in the
    // week and the activity nudge is also there).
    final badge = find.byWidgetPredicate(
      (w) => w is Text && (w.data == '1' || w.data == '2'),
    );
    expect(badge, findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Scan your first lab report'), findsOneWidget);

    await tester.tap(find.byType(DsBackButton));
    await tester.pumpAndSettle();
    expect(badge, findsNothing);
  });

  testWidgets('text size can be changed from the profile', (tester) async {
    await openAppShell(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Standard'), findsOneWidget);

    await tester.tap(find.text('Text size'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(find.text('Large'), findsOneWidget);
  });

  testWidgets('medicine reminders can be switched on', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const MedicineScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);

    await tester.tap(find.byType(DsSwitch));
    await tester.pumpAndSettle();
    expect(find.text('Shown in your notifications'), findsOneWidget);
  });

  testWidgets('without insulin the result is an estimate from the labs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'shifai_profile': '{"age":45,"female":true,"heightCm":165,"weightKg":74.9,"waistCm":90.75}',
    });
    phone(tester, h: 1800);
    final record = LabRecord(
      id: 'e',
      date: DateTime(2026, 10, 12),
      fastingGlucoseMgdl: 118,
      hba1cPercent: 6.2,
      triglyceridesMgdl: 240,
      hdlMgdl: 34,
    );
    await tester.pumpWidget(_app(ResultScreen(record: record)));
    await tester.pumpAndSettle();

    expect(find.text('Your\nestimate'), findsOneWidget);
    expect(find.textContaining('without an insulin test'), findsOneWidget);
    expect(find.textContaining('Mainly because of'), findsOneWidget);
    // poor labs give a high estimate, so a doctor is suggested
    expect(find.text('High risk'), findsOneWidget);
    expect(find.text('See a doctor about this result'), findsOneWidget);
  });

  testWidgets('the estimate asks for measurements when they are missing', (
    tester,
  ) async {
    phone(tester, h: 1800);
    final record = LabRecord(
      id: 'e2',
      date: DateTime(2026, 10, 12),
      fastingGlucoseMgdl: 90,
      hba1cPercent: 5.2,
      triglyceridesMgdl: 90,
      hdlMgdl: 55,
    );
    await tester.pumpWidget(_app(ResultScreen(record: record)));
    await tester.pumpAndSettle();
    expect(find.text('Add my measurements'), findsOneWidget);
    expect(find.text('High risk'), findsNothing);
  });

  testWidgets('only a high band suggests a doctor on the result screen', (
    tester,
  ) async {
    phone(tester);
    LabRecord record(double glucose, double insulin) => LabRecord(
      id: 'r',
      date: DateTime(2026, 10, 12),
      fastingGlucoseMgdl: glucose,
      fastingInsulinUiuml: insulin,
    );

    await tester.pumpWidget(_app(ResultScreen(record: record(85, 6))));
    await tester.pumpAndSettle();
    expect(find.text('See a doctor about this result'), findsNothing);

    await tester.pumpWidget(_app(ResultScreen(record: record(112, 12.5))));
    await tester.pumpAndSettle();
    expect(find.text('See a doctor about this result'), findsOneWidget);
  });

  testWidgets('adding and dismissing a lab marker disposes fields safely', (
    tester,
  ) async {
    phone(tester, h: 3200);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LabEntryFormScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add another lab value'));
    await tester.pumpAndSettle();
    // five value fields come first (glucose, insulin, HbA1c, triglycerides, HDL)
    await tester.enterText(find.byType(TextFormField).at(5), 'Vitamin D');
    await tester.enterText(find.byType(TextFormField).at(6), '30');
    await tester.enterText(find.byType(TextFormField).at(7), 'ng/mL');
    await tester.tap(find.text('Add marker'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vitamin D'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Add another lab value'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vitamin D'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('languages', () {
    setUpAll(initializeDateFormatting);
    tearDown(() {
      L10n.current = AppLanguage.en;
      Intl.defaultLocale = 'en';
    });

    for (final lang in AppLanguage.values) {
      testWidgets('main screens lay out in ${lang.name}', (tester) async {
        final screens = <Widget>[
          const WelcomeScreen(),
          const AppShell(),
          const WellnessScreen(),
          const WellnessScreen(startOnMove: true),
          const SkinCheckScreen(),
          const FindDoctorScreen(),
          const MedicineScreen(),
          const EmergencyScreen(),
          const ShortcutsScreen(),
          const SearchScreen(),
          const AuthScreen(),
          const AuthScreen(start: AuthStart.createAccount),
          const LabEntryFormScreen(),
          const NotificationsScreen(),
          const ProfileFormScreen(),
          BookScreen(doctor: doctorsIn('Fès').first),
        ];
        for (final screen in screens) {
          phone(tester, h: 2600);
          await tester.pumpWidget(_appIn(lang, screen));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$screen');
          await tester.pumpWidget(const SizedBox());
        }
      });
    }

    testWidgets('Eat and move switches to Arabic, right to left', (
      tester,
    ) async {
      phone(tester, h: 2600);
      await tester.pumpWidget(_appIn(AppLanguage.ar, const WellnessScreen()));
      await tester.pumpAndSettle();
      expect(find.text('كوّن صحنك'), findsOneWidget);
      expect(find.text('العدس، الحمص، الفاصوليا'), findsOneWidget);
      final dir = Directionality.of(tester.element(find.text('كوّن صحنك')));
      expect(dir, TextDirection.rtl);
    });

    testWidgets('the header button changes the language', (tester) async {
      phone(tester);
      await tester.pumpWidget(_appIn(AppLanguage.en, const AppShell()));
      await tester.pumpAndSettle();
      expect(find.text('Quick actions'), findsOneWidget);

      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(L10n.current, AppLanguage.fr);
      expect(
        (await SharedPreferences.getInstance()).getString('shifai_language'),
        'fr',
      );
    });

    test('untranslated text falls back to English', () {
      L10n.current = AppLanguage.fr;
      expect('Search'.tr, 'Rechercher');
      expect('Not a key in the tables'.tr, 'Not a key in the tables');
      expect('Welcome, {name}'.trf({'name': 'Sara'}), 'Bienvenue, Sara');
    });
  });
}

/// The app in [lang], the way main.dart sets it up.
Widget _appIn(AppLanguage lang, Widget home) {
  L10n.current = lang;
  Intl.defaultLocale = lang.intlLocale;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LabRecordsProvider()),
      ChangeNotifierProvider(create: (_) => CoachingProvider()),
      ChangeNotifierProvider(create: (_) => NavProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider(model: testModel)),
      ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ChangeNotifierProvider(create: (_) => MedicineProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ChangeNotifierProvider(create: (_) => SkinCheckProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: lang.materialLocale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}
