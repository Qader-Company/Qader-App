import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'app/env/app_env.dart';
import 'core/bloc/bloc_observer.dart';
import 'core/di/service_locator.dart';
import 'core/locale/language_manager.dart';
import 'core/storage/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  AppEnv.init(switch (name) {
    'prod' => Environment.prod,
    'staging' => Environment.staging,
    _ => Environment.dev,
  }, splashDuration: const Duration(milliseconds: 1800));
  Bloc.observer = AppBlocObserver();
  await EasyLocalization.ensureInitialized();
  await initServiceLocator();
  runApp(
    EasyLocalization(
      supportedLocales: const [englishLocale, arabicLocale],
      path: assetPathLanguage,
      startLocale: await sl<AppPreferences>().getLocale(),
      saveLocale: false,
      child: const MyApp(),
    ),
  );
}
