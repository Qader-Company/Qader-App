import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/features/offers/presentation/preview/offers_preview_data.dart';
import 'package:qader/features/offers/presentation/view/offer_details_view.dart';
import 'package:qader/features/offers/presentation/view/offers_view.dart';

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

GoRouter _router() => GoRouter(
  initialLocation: AppRouter.offers,
  routes: [
    GoRoute(
      path: AppRouter.offers,
      builder: (_, _) => OffersView(offers: OffersPreviewData.offers),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => OfferDetailsView(
            offer: OffersPreviewData.byId(state.pathParameters['id']!)!,
          ),
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('offers list, every details stage and both dialogs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final family in ['Poppins', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    final router = _router();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp.router(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeManager.getTheme(context.locale),
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> capture(String name, double height) async {
      tester.view.physicalSize = Size(390, height);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/design_review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // List: four cards, then the second page.
    expect(find.text('My Offers'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('Awaiting Your Response'), findsOneWidget);
    expect(find.text('Clear Filters'), findsNothing);
    await capture('offers_list', 1300);
    await tap(find.widgetWithText(OutlinedButton, 'Next'));
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('Contracted'), findsOneWidget);

    // Search and status filter, then clear both.
    await tester.enterText(find.byType(TextFormField).first, 'react');
    await tester.pumpAndSettle();
    expect(find.text('React Developer'), findsOneWidget);
    expect(find.text('Page 1 of 1'), findsOneWidget);
    await tap(find.byKey(const ValueKey('offers-status-filter')));
    await tap(find.text('Rejected').last);
    expect(
      find.text('No offers match your search or filters.'),
      findsOneWidget,
    );
    await tap(find.text('Clear Filters'));
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      isEmpty,
    );

    // Details of each stage.
    final stages = {
      '1': ('offer_details_awaiting', 1500.0),
      '2': ('offer_details_negotiating', 2300.0),
      '3': ('offer_details_waiting_interview', 1300.0),
      '4': ('offer_details_interview', 1300.0),
      '5': ('offer_details_interview_cancelled', 1200.0),
      '6': ('offer_details_contracted', 1400.0),
      '7': ('offer_details_rejected', 1500.0),
      '8': ('offer_details_cancelled', 1800.0),
    };
    for (final MapEntry(key: id, value: (name, height)) in stages.entries) {
      router.go('${AppRouter.offers}/$id');
      await tester.pumpAndSettle();
      expect(find.text('Back to offers'), findsOneWidget);
      await capture(name, height);
    }

    // Counter offer: validation, then the not-connected notice.
    router.go('${AppRouter.offers}/1');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tap(find.widgetWithText(OutlinedButton, 'Negotiate'));
    expect(find.text('Submit Counter Offer'), findsOneWidget);
    await capture('offer_counter_dialog', 844);
    await tap(find.text('Send Counter Offer'));
    expect(find.text('This field is required'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Riyadh, Saudi Arabia'),
      'Riyadh, Saudi Arabia',
    );
    await tap(find.text('Send Counter Offer'));
    expect(find.text('Submit Counter Offer'), findsNothing);
    expect(
      find.text('Offers are not connected yet, so nothing was sent.'),
      findsOneWidget,
    );
    await tap(find.text('Confirm'));

    // Apologize from the interview menu.
    router.go('${AppRouter.offers}/4');
    await tester.pumpAndSettle();
    await tap(find.byTooltip('More actions'));
    await tap(find.text('Apologize'));
    expect(find.text('Apologize & Reschedule'), findsOneWidget);
    await capture('offer_apologize_dialog', 844);
    await tap(find.text('Submit Apology & Reschedule'));
    expect(find.text('Please write at least 10 characters'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('apologize-reason')),
      'I have a medical appointment at that time.',
    );
    await tap(find.text('Submit Apology & Reschedule'));
    expect(find.text('Apologize & Reschedule'), findsNothing);
    await tap(find.text('Confirm'));

    // Arabic, narrow screen: no overflow on any page.
    await tester
        .element(find.byType(OfferDetailsView))
        .setLocale(const Locale('ar', 'SA'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 2300);
    for (final id in [...stages.keys]) {
      router.go('${AppRouter.offers}/$id');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'offer $id');
    }
    router.go(AppRouter.offers);
    await tester.pumpAndSettle();
    expect(find.text('عروضي'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('offers_list_ar', 1300);
  });
}
