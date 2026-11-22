import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'l10n/l10n.dart';
import 'providers/activity_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/coaching_provider.dart';
import 'providers/language_provider.dart';
import 'providers/lab_records_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/skin_check_provider.dart';
import 'screens/app_root_gate.dart';
import 'services/lab_cloud_service.dart';
import 'services/risk_model.dart';
import 'services/secure_supabase_storage.dart';
import 'theme/app_theme.dart';

import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and day names for French and Arabic dates.
  await initializeDateFormatting();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSupabaseLocalStorage(),
        pkceAsyncStorage: SecureSupabasePkceStorage(),
      ),
    );
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ShifAiApp(),
    ),
  );
}

class ShifAiApp extends StatelessWidget {
  /// Optional pre-loaded risk model (tests); normally loaded from assets.
  final RiskModel? riskModel;
  const ShifAiApp({super.key, this.riskModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LabRecordsProvider>(
          create: (_) => LabRecordsProvider(
            cloud: SupabaseConfig.isConfigured
                ? LabCloudService(Supabase.instance.client)
                : null,
          ),
          update: (_, auth, records) {
            records!.setAccount(auth.user?.id);
            return records;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CoachingProvider>(
          create: (_) => CoachingProvider(
            client: SupabaseConfig.isConfigured
                ? Supabase.instance.client
                : null,
          ),
          update: (_, auth, coaching) {
            coaching!.setAccount(auth.user?.id);
            return coaching;
          },
        ),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(model: riskModel),
        ),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => SkinCheckProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Builder(
        builder: (context) {
          final language = context.watch<LanguageProvider>().language;
          return MaterialApp(
            // A new key rebuilds every screen in the chosen language.
            key: ValueKey(language),
            locale: language.materialLocale,
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) {
              final wrapped = DevicePreview.appBuilder(context, child);
              // The text size chosen in Profile, on top of the phone's own setting.
              final factor = context.watch<SettingsProvider>().textScale;
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(
                    media.textScaler.scale(1.0) * factor,
                  ),
                ),
                child: wrapped,
              );
            },
            title: 'ShifAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const AppRootGate(),
          );
        },
      ),
    );
  }
}
