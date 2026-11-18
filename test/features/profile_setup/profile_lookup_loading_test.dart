import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/widgets/skeleton.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_lookup_select.dart';

class _Fields extends Fake implements ProfessionalFieldsRepository {}

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
  testWidgets('dropdowns and chips shimmer until their options arrive', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final draft = ProfileSetupCubit(fieldsRepository: _Fields());
    addTearDown(draft.close);
    draft.selectValues('skill_ids', {});
    draft.lookupLoading.addAll({ProfileLookup.countries, ProfileLookup.skills});

    Future<void> pump() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: Column(
                  children: [
                    ProfileLookupSelect(
                      'Country',
                      draft: draft,
                      lookup: ProfileLookup.countries,
                      value: null,
                      onChanged: (_) {},
                    ),
                    ProfileLookupMultiSelect(
                      'Skills',
                      draft: draft,
                      lookup: ProfileLookup.skills,
                      selectionKey: 'skill_ids',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    await pump();
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.byType(Shimmer), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    draft.lookupLoading.clear();
    draft.lookupOptions.addAll({
      ProfileLookup.countries: const [
        ProfileLookupOption(value: 1, label: 'Egypt'),
      ],
      ProfileLookup.skills: const [
        ProfileLookupOption(value: 3, label: 'JavaScript'),
      ],
    });
    await pump();
    await tester.pumpAndSettle();
    expect(find.byType(Shimmer), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'JavaScript'), findsOneWidget);
  });
}
