import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/di/dependencies.dart';
import 'package:qader/core/env/app_env.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/workspaces/domain/entities/workspace_lookup.dart';
import 'package:qader/features/workspaces/presentation/view/workspace_dashboard_view.dart';

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

/// The industry, country and city dropdowns, in that order.
final _lookup = find.byType(DropdownButton<WorkspaceLookup>);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GlobalKey captureKey;

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    AppEnv.init(Environment.dev);
    await EasyLocalization.ensureInitialized();
    await initServiceLocator(
      preferencesOverride: AppPreferencesImpl(
        await SharedPreferences.getInstance(),
      ),
    );
    addTearDown(sl.reset);
    for (final family in ['Poppins', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EasyLocalization(
          supportedLocales: const [englishLocale, arabicLocale],
          path: assetPathLanguage,
          startLocale: englishLocale,
          saveLocale: false,
          assetLoader: const _Translations(),
          child: const MyApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
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
  }

  Future<void> go(WidgetTester tester, String location) async {
    AppRouter.router.go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('a client without workspaces is invited to create one', (
    tester,
  ) async {
    await start(tester);
    await go(tester, '${AppRouter.workspaces}?preview=true&empty=true');
    expect(
      find.text("Welcome, Let's create your first workspace"),
      findsOneWidget,
    );
    expect(find.text('Bring your team together'), findsOneWidget);
    await capture(tester, 'workspace_first');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Workspace'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('picking a workspace opens its dashboard', (tester) async {
    await start(tester);
    await go(tester, '${AppRouter.workspaces}?preview=true');
    expect(find.text('Lomee Florist'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Orascom'), 200);
    await tester.tap(find.text('Orascom'));
    await tester.pumpAndSettle();
    await capture(tester, 'workspace_choose');
    await tester.tap(find.text('Go to client portal'));
    await tester.pumpAndSettle();
    final dashboard = tester.widget<WorkspaceDashboardView>(
      find.byType(WorkspaceDashboardView),
    );
    expect(dashboard.workspaceId, 'orascom');
    expect(find.text('Welcome to Your Workspace'), findsOneWidget);
    expect(find.text('Recent Hiring Requests'), findsOneWidget);
    await capture(tester, 'workspace_dashboard');

    await tester.element(find.byType(MyApp)).setLocale(arabicLocale);
    await tester.pumpAndSettle();
    await capture(tester, 'workspace_dashboard_arabic');
    await go(tester, '${AppRouter.workspaces}?preview=true');
    await capture(tester, 'workspace_choose_arabic');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an empty workspace offers ways to build the team', (
    tester,
  ) async {
    await start(tester);
    await go(
      tester,
      '${AppRouter.workspaceDashboard}?id=new&preview=true&empty=true',
    );
    expect(find.text('Build Your Team'), findsOneWidget);
    await capture(tester, 'workspace_dashboard_empty');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Browse'));
    await tester.pumpAndSettle();
    expect(find.text('This service is not connected yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the create form checks its fields, then opens the dashboard', (
    tester,
  ) async {
    await start(tester);
    await go(tester, '${AppRouter.createWorkspace}?preview=true');
    await capture(tester, 'workspace_create');

    final create = find.widgetWithText(ElevatedButton, 'Create workspace');
    await tester.scrollUntilVisible(
      create,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsWidgets);
    expect(find.byType(WorkspaceDashboardView), findsNothing);

    // A company also gives its tax card and CR number.
    await tester.scrollUntilVisible(
      find.text('Yes'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tax Card', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('CR Number', findRichText: true),
      findsOneWidget,
    );
    await capture(tester, 'workspace_create_company');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tax Card', findRichText: true), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('Workspace Name', findRichText: true),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Lomee Florist'),
      'Qader Technology',
    );
    await tester.tap(_lookup.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retail').hitTestable().last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter a description...'),
      'Digital products',
    );
    await tester.scrollUntilVisible(
      find.text('Select Country'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(_lookup.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Egypt').hitTestable().last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('11-50'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('11-50'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      create,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceDashboardView), findsOneWidget);
    expect(find.text('Your workspace is ready.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
