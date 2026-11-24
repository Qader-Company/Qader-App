import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/domain/entities/account_role.dart';
import 'package:qader/features/auth/domain/entities/auth_user.dart';
import 'package:qader/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:qader/features/home/presentation/view/widgets/home_drawer.dart';

class _Prefs extends Fake implements AppPreferences {
  _Prefs({this.loggedIn = true});
  final bool loggedIn;
  @override
  bool get isLoggedIn => loggedIn;
  @override
  String getUserName() => 'Saved Name';
  @override
  String getUserEmail() => 'saved@qader.test';
}

class _Session extends Fake implements AuthSessionCubit {
  _Session([this.user]);
  final AuthUser? user;
  int logouts = 0;
  @override
  AuthSessionState get state =>
      AuthSessionState(AuthStatus.authenticated, user: user);
  @override
  Future<void> logout() async => logouts++;
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

const _sara = AuthUser(
  id: 1,
  role: AccountRole.talent,
  firstName: 'Sara',
  lastName: 'Ali',
  email: 'sara@qader.test',
  isActive: true,
  isEmailVerified: true,
);

/// A home screen with the drawer open, plus every route it can open.
Future<GoRouter> _open(
  WidgetTester tester, {
  required AppPreferences prefs,
  AuthSessionCubit? session,
  bool preview = false,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  final scaffold = GlobalKey<ScaffoldState>();
  Widget page(String name) => Scaffold(body: Text('page $name'));
  final router = GoRouter(
    initialLocation: AppRouter.home,
    routes: [
      GoRoute(
        path: AppRouter.home,
        builder: (_, _) => Scaffold(
          key: scaffold,
          drawer: HomeDrawer(preview: preview),
          body: const Text('page home'),
        ),
      ),
      for (final path in [
        AppRouter.talentProfile,
        AppRouter.offers,
        AppRouter.chooseRole,
        AppRouter.profileSetup,
      ])
        GoRoute(path: path, builder: (_, _) => page(path)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
      startLocale: const Locale('en', 'US'),
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _Translations(),
      child: Builder(
        builder: (context) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppPreferences>.value(value: prefs),
            if (session != null)
              RepositoryProvider<AuthSessionCubit>.value(value: session),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  scaffold.currentState!.openDrawer();
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('shows the session name, or the saved one, or Guest', (
    tester,
  ) async {
    await _open(tester, prefs: _Prefs(), session: _Session(_sara));
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('sara@qader.test'), findsOneWidget);
    expect(find.text('SA'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _open(tester, prefs: _Prefs());
    expect(find.text('Saved Name'), findsOneWidget);
    expect(find.text('saved@qader.test'), findsOneWidget);
  });

  testWidgets('items open their screens; unbuilt ones say coming soon', (
    tester,
  ) async {
    final router = await _open(tester, prefs: _Prefs());
    // Design previews only show in preview.
    expect(find.text('Design previews'), findsNothing);

    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();
    expect(find.text('page ${AppRouter.talentProfile}'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('logout ends the session and goes to choose role', (
    tester,
  ) async {
    final session = _Session(_sara);
    await _open(tester, prefs: _Prefs(), session: session);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(session.logouts, 1);
    expect(find.text('page ${AppRouter.chooseRole}'), findsOneWidget);
  });

  testWidgets('signed out, logout only leaves; previews are listed', (
    tester,
  ) async {
    final session = _Session();
    await _open(
      tester,
      prefs: _Prefs(loggedIn: false),
      session: session,
      preview: true,
    );
    expect(find.text('Design previews'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(session.logouts, 0);
    expect(find.text('page ${AppRouter.chooseRole}'), findsOneWidget);
  });
}
