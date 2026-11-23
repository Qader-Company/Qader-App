import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_details.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/view/live_offer_details_view.dart';

class _Repo extends Fake implements OffersRepository {
  _Repo(this.failure);
  final Failure failure;
  int loads = 0;
  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async {
    loads++;
    return Left(failure);
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
  testWidgets('a 404 says the offer is gone and leads back to the list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    Future<void> pump(_Repo repo) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: RepositoryProvider<OffersRepository>.value(
            value: repo,
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                routerConfig: GoRouter(
                  initialLocation: '${AppRouter.offers}/11',
                  routes: [
                    GoRoute(
                      path: AppRouter.offers,
                      builder: (_, _) =>
                          const Scaffold(body: Text('Offers list')),
                      routes: [
                        GoRoute(
                          path: ':id',
                          builder: (_, state) => LiveOfferDetailsView(
                            key: UniqueKey(),
                            offerId: state.pathParameters['id']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    // The API's "No query results for model [HiringRequestItem] 11".
    await pump(
      _Repo(
        const ServerFailure(
          message: 'No query results for model HiringRequestItem 11',
          statusCode: 404,
        ),
      ),
    );
    expect(find.text('This offer is no longer available'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Back to offers'));
    await tester.pumpAndSettle();
    expect(find.text('Offers list'), findsOneWidget);

    // Other failures still offer a retry.
    final offline = _Repo(const NetworkFailure(message: 'offline'));
    await pump(offline);
    expect(find.text("We couldn't load this offer."), findsOneWidget);
    expect(find.text('This offer is no longer available'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
