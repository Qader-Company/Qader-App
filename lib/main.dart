import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'app/push_startup.dart';
import 'core/env/app_env.dart';
import 'core/bloc/bloc_observer.dart';
import 'app/di/dependencies.dart';
import 'core/locale/language_manager.dart';
import 'core/notifications/push_notifications.dart';
import 'core/storage/app_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  AppEnv.init(switch (name) {
    'prod' => Environment.prod,
    'staging' => Environment.staging,
    _ => Environment.dev,
  }, splashDuration: const Duration(milliseconds: 1800));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Bloc.observer = AppBlocObserver();
  await EasyLocalization.ensureInitialized();
  await initServiceLocator();
  unawaited(startPushNotifications(sl<PushNotifications>()));
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
