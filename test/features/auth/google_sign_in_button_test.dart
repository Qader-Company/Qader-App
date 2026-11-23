import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/router/route_args.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/domain/entities/account_role.dart';
import 'package:qader/features/auth/domain/entities/auth_user.dart';
import 'package:qader/features/auth/domain/entities/google_account.dart';
import 'package:qader/features/auth/domain/repositories/auth_repository.dart';
import 'package:qader/features/auth/domain/repositories/google_sign_in_client.dart';
import 'package:qader/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:qader/features/auth/presentation/view/widgets/google_sign_in_button.dart';

class _Client implements GoogleSignInClient {
  @override
  Future<Either<Failure, GoogleAccount?>> signIn() async =>
      const Right(GoogleAccount(idToken: 'google-id-token', name: 'Sara Ali'));
}

class _Repo extends Fake implements AuthRepository {
  final tokens = <String>[];
  Failure? failure;
  @override
  Future<Either<Failure, AuthUser>> googleLogin(
    String idToken, {
    String? name,
  }) async {
    tokens.add('$idToken / $name');
    if (failure case final failure?) return Left(failure);
    return const Right(
      AuthUser(
        id: 2,
        firstName: 'Sara',
        lastName: 'Ali',
        email: 'sara@example.test',
        role: AccountRole.talent,
        isActive: true,
        isEmailVerified: true,
      ),
    );
  }
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

void main() {
  testWidgets('a picked Google account signs in and opens profile setup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
    final repo = _Repo();
    final session = AuthSessionCubit(repo, prefs);
    addTearDown(session.close);
    ProfileSetupSeed? seed;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
        startLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<GoogleSignInClient>.value(value: _Client()),
            RepositoryProvider<AuthSessionCubit>.value(value: session),
          ],
          child: Builder(
            builder: (context) => MaterialApp.router(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const Scaffold(
                      body: Center(child: GoogleSignInButton()),
                    ),
                  ),
                  GoRoute(
                    path: AppRouter.profileSetup,
                    builder: (_, state) {
                      seed = state.extra as ProfileSetupSeed?;
                      return const Scaffold(body: Text('Profile setup'));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A backend failure stays on the page with its message.
    repo.failure = const ServerFailure(message: 'auth_account_inactive');
    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();
    expect(repo.tokens, ['google-id-token / Sara Ali']);
    expect(find.text('Profile setup'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);

    // Success: the session opens profile setup like the email login.
    repo.failure = null;
    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();
    expect(repo.tokens, hasLength(2));
    expect(find.text('Profile setup'), findsOneWidget);
    expect(seed?.email, 'sara@example.test');
    expect(seed?.name, 'Sara Ali');
    expect(tester.takeException(), isNull);
  });
}
