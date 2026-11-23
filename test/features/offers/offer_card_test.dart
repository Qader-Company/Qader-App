import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_summary.dart';
import 'package:qader/features/offers/presentation/widgets/offer_card.dart';

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

HiringOfferSummary _offer(
  String id, {
  String status = 'offer',
  String latest = '',
  String label = '',
  bool byTalent = false,
}) => HiringOfferSummary(
  id: id,
  status: status,
  statusLabel: status == 'offer' ? 'Offer' : 'Interview',
  companyName: 'Qader Technology',
  jobTitle: 'Backend Developer',
  latestStatus: latest,
  latestStatusLabel: label,
  latestByTalent: byTalent,
);

void main() {
  testWidgets('cards show where the newest offer stands', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final offers = [
      _offer('1', latest: 'pending', label: 'Pending'),
      _offer('2', latest: 'pending', label: 'Pending', byTalent: true),
      _offer('3', latest: 'expired', label: 'Expired'),
      // Past the offer stage the item chip says it all.
      _offer('4', status: 'interview', latest: 'accepted', label: 'Accepted'),
      // No `offer` in the response: no second chip.
      _offer('5'),
    ];
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
        startLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeManager.getTheme(context.locale),
            home: Scaffold(
              body: ListView(
                children: [
                  for (final offer in offers)
                    OfferCard(
                      key: ValueKey('card-${offer.id}'),
                      offer: offer,
                      onOpen: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder inCard(String id, String text) => find.descendant(
      of: find.byKey(ValueKey('card-$id')),
      matching: find.text(text),
    );
    expect(inCard('1', 'Awaiting your response'), findsOneWidget);
    expect(inCard('2', 'Waiting for the company'), findsOneWidget);
    expect(inCard('3', 'Expired'), findsOneWidget);
    expect(inCard('4', 'Accepted'), findsNothing);
    expect(inCard('4', 'Interview'), findsOneWidget);
    for (final id in ['4', '5']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('card-$id')),
          matching: find.text('Pending'),
        ),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
