import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/features/home/domain/talent_application.dart';
import 'package:qader/features/home/presentation/status_copy.dart';
import 'package:qader/features/home/presentation/view/application_status_view.dart';

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

TalentApplication _rejected({required bool canReapply, String? reapplyAt}) =>
    TalentApplication.fromJson({
      'id': 1,
      'status': 'rejected',
      'status_label': 'Rejected',
      'screen_state': 'rejected',
      'reapply_at': reapplyAt,
      'can_reapply': canReapply,
      'interview_history': <Object>[],
      'faqs': <Object>[],
    });

void main() {
  Future<void> mount(WidgetTester tester, TalentApplication app) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
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
            home: ApplicationStatusView(
              initialStatus: app.viewStatus!,
              application: app,
              userName: 'Ahmed',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rejected with can_reapply enables Apply Again', (tester) async {
    await mount(
      tester,
      _rejected(canReapply: true, reapplyAt: '2026-10-21T09:00:00.000000Z'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Rejected'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Apply Again'), findsOneWidget);
    expect(
      find.textContaining('reapplication period has ended. You can now'),
      findsOneWidget,
    );
  });

  testWidgets('rejected without can_reapply keeps Apply Again disabled', (
    tester,
  ) async {
    await mount(
      tester,
      _rejected(
        canReapply: false,
        reapplyAt: DateTime.now()
            .add(const Duration(days: 30))
            .toUtc()
            .toIso8601String(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(ElevatedButton, 'Apply Again'), findsNothing);
    expect(find.text('Apply Again'), findsOneWidget);
  });

  // "Interview slot required" example from Apidog (trimmed).
  Map<String, dynamic> slotRequired({Map<String, bool>? actions}) {
    Map<String, dynamic> interview() => {
      'id': 11,
      'round_number': 1,
      'type': 'technical',
      'status': 'awaiting_slot_selection',
      'status_label': 'Awaiting Slot Selection',
      'available_slots': [
        {
          'id': 21,
          'mode': 'online',
          'start': '2026-11-12T10:00:00.000000Z',
          'end': '2026-11-12T11:00:00.000000Z',
          'duration_minutes': 60,
          'location': null,
          'latitude': null,
          'longitude': null,
          'status': 'available',
          'is_selectable': true,
        },
        {
          'id': 22,
          'mode': 'offline',
          'start': '2026-11-13T13:00:00.000000Z',
          'end': '2026-11-13T14:00:00.000000Z',
          'duration_minutes': 60,
          'location': 'Qader HQ, King Fahd Road, Riyadh',
          'latitude': '24.7136000',
          'longitude': '46.6753000',
          'status': 'available',
          'is_selectable': true,
        },
      ],
      'selected_slot': null,
      'meeting_url': null,
      'completed_at': null,
      'slot_rejections': {'used': 0, 'maximum': 2, 'remaining': 2},
      'talent_reschedule_used_at': null,
      'actions':
          actions ??
          {
            'can_select_slot': true,
            'can_reject_all_slots': true,
            'can_cancel_and_reschedule': false,
            'can_join': false,
          },
    };
    return {
      'id': 1,
      'status': 'interview_required',
      'status_label': 'Interview Required',
      'screen_state': 'interview_slot_required',
      'interview': interview(),
      'current_interview': interview(),
      'interview_history': [interview()],
      'faqs': <Object>[],
    };
  }

  test('interview slot required example parses as expected', () {
    final app = TalentApplication.fromJson(slotRequired());
    expect(app.viewStatus, ApplicationStatus.slots);
    expect(app.history, isEmpty, reason: 'current interview is not history');
    expect(app.slots.map((slot) => slot.id), [21, 22]);
    expect(app.slots.last.online, isFalse);
    expect(app.slots.last.latitude, 24.7136);
    final interview = app.interview!;
    expect(interview.round, 1);
    expect(interview.type, 'technical');
    expect(interview.rejectionsRemaining, 2);
    expect(interview.actions.canSelectSlot, isTrue);
    expect(interview.actions.canCancelAndReschedule, isFalse);
  });

  testWidgets('slot screen renders API slots and follows actions', (
    tester,
  ) async {
    final app = TalentApplication.fromJson(slotRequired());
    await mount(tester, app);
    expect(tester.takeException(), isNull);
    expect(find.text('Interview Required'), findsOneWidget);
    expect(find.text('Qader HQ, King Fahd Road, Riyadh'), findsOneWidget);
    expect(find.text('Interview History'), findsNothing);
    expect(find.text('Technical Interview'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Confirm Selected Slot'),
      findsOneWidget,
    );

    final locked = TalentApplication.fromJson(
      slotRequired(
        actions: {'can_select_slot': false, 'can_reject_all_slots': false},
      ),
    );
    await mount(tester, locked);
    expect(find.byTooltip('More actions'), findsNothing);
    expect(
      find.widgetWithText(ElevatedButton, 'Confirm Selected Slot'),
      findsNothing,
    );
  });
}
