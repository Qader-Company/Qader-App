import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/features/profile_setup/presentation/view/profile_setup_view.dart';
import 'package:qader/features/profile_setup/presentation/widgets/basic_info_step.dart';
import 'package:qader/features/profile_setup/presentation/widgets/skills_experience_step.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_widgets.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_upload.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode!}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

class _Picker extends FilePicker {
  FilePickerResult? result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Profile wizard: files, validation, draft, repeaters, salary and Arabic layout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 848);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      AppEnv.init(Environment.dev, splashDuration: const Duration(seconds: 1));
      await EasyLocalization.ensureInitialized();
      await initServiceLocator();
      for (final family in ['Poppins', 'Rubik']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      final picker = _Picker();
      FilePicker.platform = picker;
      final captureKey = GlobalKey();
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
      AppRouter.router.go(AppRouter.home);
      await tester.pumpAndSettle();
      // The new flow must be reachable from the actual application drawer.
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview talent profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSetupView), findsOneWidget);
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> button(String text) async =>
          tap(find.widgetWithText(ElevatedButton, text).last);
      Finder input(String label) => find.descendant(
        of: find
            .byWidgetPredicate((w) => w is ProfileInput && w.label == label)
            .first,
        matching: find.byType(TextFormField),
      );
      Future<void> enter(String label, String value) async {
        final f = input(label);
        await tester.ensureVisible(f);
        await tester.enterText(f, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      Future<void> select(String label, String option, {int index = 0}) async {
        final f = find
            .byWidgetPredicate((w) => w is ProfileSelect && w.label == label)
            .at(index);
        await tap(
          find.descendant(
            of: f,
            matching: find.byType(DropdownButtonFormField<String>),
          ),
        );
        await tap(find.text(option).last);
      }

      Future<void> capture(String name, Size size) async {
        tester.view.physicalSize = size;
        ScaffoldMessenger.of(
          tester.element(find.byType(ProfileSetupView)),
        ).clearSnackBars();
        await tester.pumpAndSettle();
        final scroll = find.byType(SingleChildScrollView);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, 5000));
          await tester.pumpAndSettle();
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
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

      await capture('profile_field', const Size(390, 848));
      await tap(find.text('Design'));
      await button('Continue');
      final draft = tester
          .widget<BasicInfoStep>(find.byType(BasicInfoStep))
          .draft;
      expect(draft.field.name, 'Design');
      await capture('profile_basic', const Size(390, 1742));
      await button('Next');
      expect(find.text('Please select your CV'), findsOneWidget);
      picker.result = FilePickerResult([
        PlatformFile(name: 'too-big.pdf', size: 11 * 1024 * 1024),
      ]);
      await tap(find.byType(ProfileUpload));
      expect(draft.cv, isNull);
      picker.result = FilePickerResult([
        PlatformFile(name: 'cv.pdf', size: 1024),
      ]);
      await tap(find.byType(ProfileUpload));
      expect(draft.cv?.name, 'cv.pdf');
      await enter('Phone Number', '+201012345678');
      await enter('WhatsApp Number', '+201012345678');
      await select('Gender', 'Male');
      await button('Add Language');
      expect(draft.languages.length, 3);
      await tap(find.byTooltip('Remove Language 3'));
      expect(draft.languages.length, 2);
      await button('Next');
      expect(find.byType(SkillsExperienceStep), findsOneWidget);
      await capture('profile_skills', const Size(389, 2635));
      final skillInput = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller == draft.text('newSkill'),
      );
      await tester.ensureVisible(skillInput);
      await tester.enterText(skillInput, 'Flutter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(draft.skills, contains('Flutter'));
      await tap(find.byTooltip('Remove Flutter'));
      expect(draft.skills, isNot(contains('Flutter')));

      await tap(find.widgetWithText(OutlinedButton, 'Back'));
      expect(draft.text('phone').text, '+201012345678');
      expect(draft.cv?.name, 'cv.pdf');
      await button('Next');
      await button('Next');
      expect(find.text('This field is required'), findsWidgets);
      await select('Job Title', 'UI/UX Designer');
      await select('Level', 'Junior');
      await enter('Years of Experience', '3');
      await enter('LinkedIn', 'https://linkedin.com/in/olivia');
      await enter(
        'Job Title',
        'UI/UX Designer',
      ); // first match is the experience text field
      await enter('Company Name', 'Qader');
      await button('Add Experience');
      expect(draft.experiences.length, 2);
      await tap(find.byTooltip('Remove Experience 2'));
      expect(draft.experiences.length, 1);
      await button('Add Project');
      expect(draft.projects.length, 2);
      await tap(find.byTooltip('Remove Project 2'));
      expect(draft.projects.length, 1);
      await enter('Project Name', 'Qader');
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aY1kAAAAASUVORK5CYII=',
      );
      picker.result = FilePickerResult(
        List.generate(
          6,
          (i) =>
              PlatformFile(name: 'image$i.png', size: png.length, bytes: png),
        ),
      );
      await tap(find.byType(ProfileUpload));
      expect(draft.projects.first.images, isEmpty);
      picker.result = FilePickerResult([
        PlatformFile(name: 'project.png', size: png.length, bytes: png),
      ]);
      await tap(find.byType(ProfileUpload));
      expect(draft.projects.first.images.length, 1);
      await tap(find.byTooltip('Remove project.png'));
      expect(draft.projects.first.images, isEmpty);
      await button('Next');
      expect(find.text('Work Preferences'), findsOneWidget);
      await capture('profile_work', const Size(389, 951));
      await button('Submit');
      expect(find.text('This field is required'), findsWidgets);
      await tap(find.widgetWithText(OutlinedButton, 'Full Time'));
      await tap(find.widgetWithText(OutlinedButton, 'Remote'));
      await select('Notice Period', 'Immediately');
      await select('', 'USD', index: 0);
      await select('', 'USD', index: 1);
      final salaryInputs = find.byWidgetPredicate(
        (w) => w is ProfileInput && w.label.isEmpty,
      );
      Future<void> salary(int index, String value) async {
        final f = find.descendant(
          of: salaryInputs.at(index),
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(f);
        await tester.enterText(f, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      await salary(0, '5000');
      await salary(1, '1000');
      await salary(2, '0');
      await button('Submit');
      expect(find.text('Maximum must be at least minimum'), findsOneWidget);
      await salary(1, '7000');
      await button('Submit');
      expect(find.text('Submission preview'), findsOneWidget);
      await tap(find.text('Preview confirmation'));
      await capture('profile_submitted', const Size(389, 974));
      expect(find.text('Profile Submitted!'), findsOneWidget);
      // Revisit each step at 320 px with Arabic text and the existing draft intact.
      final context = tester.element(find.byType(ProfileSetupView));
      await context.setLocale(arabicLocale);
      await tester.pumpAndSettle();
      for (final step in [0, 1, 2, 3, 4]) {
        draft.go(step);
        await tester.pumpAndSettle();
        await capture('profile_ar_$step', const Size(320, 844));
      }
      expect(draft.text('phone').text, '+201012345678');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
