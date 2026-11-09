import 'package:flutter_test/flutter_test.dart';
import 'package:qader/features/home/domain/talent_application.dart';
import 'package:qader/features/home/presentation/status_copy.dart';

/// Trimmed copy of a real `GET /talent/application` test-env response.
Map<String, dynamic> _response({
  String screenState = 'interview_slot_required',
  List<Map<String, dynamic>> history = const [],
  Map<String, dynamic>? currentInterview,
}) => {
  'id': 1,
  'status': 'interview_required',
  'status_label': 'Interview Required',
  'application_status': 'interview_required',
  'effective_status': 'interview_required',
  'screen_state': screenState,
  'submitted_at': '2026-10-19T09:28:45.000000Z',
  'review_decided_at': '2026-10-27T09:29:59.000000Z',
  'reapply_at': null,
  'can_reapply': false,
  'is_blacklisted': false,
  'interview': null,
  'current_interview': currentInterview,
  'interview_history': history,
  'faqs': [
    {
      'id': 5,
      'screen_states': [
        'interview_slot_required',
        'awaiting_new_interview_slots',
        'interview_confirmed',
        'interview_completed',
      ],
      'question': 'What happens after I pass the initial review?',
      'answer': 'Choose one of the available interview time slots.',
      'display_order': 4,
      'is_active': true,
    },
    {
      'id': 2,
      'screen_states': ['under_review', 'interview_slot_required'],
      'question': 'How long does the review process take?',
      'answer': 'The review time may vary.',
      'display_order': 1,
      'is_active': true,
    },
    {
      'id': 9,
      'screen_states': ['rejected'],
      'question': 'Rejected only',
      'answer': 'x',
      'display_order': 0,
      'is_active': true,
    },
  ],
};

void main() {
  test('parses the API response and maps screen_state', () {
    final app = TalentApplication.fromJson(_response());
    expect(app.id, 1);
    expect(app.screenState, 'interview_slot_required');
    expect(app.statusLabel, 'Interview Required');
    expect(app.viewStatus, ApplicationStatus.slots);
    expect(app.interview, isNull);
    expect(app.slots, isEmpty);
    expect(app.submittedAt, isNotNull);
    expect(app.reapplyAt, isNull);
    expect(app.screenFaqs.map((faq) => faq.question), [
      'How long does the review process take?',
      'What happens after I pass the initial review?',
    ]);
  });

  test('maps every known screen_state', () {
    ApplicationStatus? map(
      String state, {
      List<Map<String, dynamic>> history = const [],
    }) => TalentApplication.fromJson(
      _response(screenState: state, history: history),
    ).viewStatus;

    expect(map('under_review'), isNull);
    expect(map('awaiting_new_interview_slots'), ApplicationStatus.cancelled);
    expect(map('interview_confirmed'), ApplicationStatus.confirmed);
    expect(map('interview_in_progress'), ApplicationStatus.confirmed);
    expect(map('interview_cancelled'), ApplicationStatus.cancelled);
    expect(map('interview_completed'), ApplicationStatus.completed);
    expect(map('accepted'), ApplicationStatus.accepted);
    expect(map('rejected'), ApplicationStatus.rejected);
    expect(
      map(
        'rejected',
        history: [
          {'id': 1, 'status': 'completed'},
        ],
      ),
      ApplicationStatus.rejectedAfterInterview,
    );
    expect(
      map(
        'interview_slot_required',
        history: [
          {'id': 1, 'status': 'cancelled_by_admin'},
        ],
      ),
      ApplicationStatus.newSlots,
    );
  });

  test('reads interview and slots in the backend shape', () {
    // Shape of the interview object from the admin "Offer Replacement
    // Interview Slots" response in the OpenAPI export.
    Map<String, dynamic> slot(int id, String mode, String status) => {
      'id': id,
      'mode': mode,
      'start': '2026-11-0${id}T10:00:00.000000Z',
      'end': '2026-11-0${id}T11:00:00.000000Z',
      'location': mode == 'offline' ? 'Qader Office, Giza' : null,
      'latitude': mode == 'offline' ? '30.04442' : null,
      'longitude': mode == 'offline' ? '31.235712' : null,
      'status': status,
    };
    final choosing = TalentApplication.fromJson(
      _response(
        currentInterview: {
          'id': 1,
          'type': 'technical',
          'status': 'awaiting_slot_selection',
          'interviewers': <Object>[],
          'slots': [
            slot(4, 'online', 'available'),
            slot(5, 'offline', 'available'),
            slot(6, 'online', 'expired'),
          ],
          'meeting_url': null,
        },
      ),
    );
    expect(choosing.viewStatus, ApplicationStatus.slots);
    expect(choosing.interview!.type, 'technical');
    expect(choosing.slots.map((s) => s.id), [4, 5]);
    expect(choosing.slots.first.online, isTrue);
    expect(choosing.slots.first.end, isNotNull);
    expect(choosing.slots.last.online, isFalse);
    expect(choosing.slots.last.location, 'Qader Office, Giza');
    expect(choosing.slots.last.latitude, 30.04442);

    final confirmed = TalentApplication.fromJson(
      _response(
        screenState: 'interview_confirmed',
        currentInterview: {
          'id': 1,
          'type': 'hr',
          'status': 'confirmed',
          'slots': [
            slot(4, 'online', 'cancelled'),
            slot(5, 'offline', 'selected'),
          ],
          'meeting_url': 'https://meet.google.com/abc-defg-hij',
        },
      ),
    );
    final interview = confirmed.interview!;
    expect(confirmed.viewStatus, ApplicationStatus.confirmed);
    expect(interview.start, DateTime.parse('2026-11-05T10:00:00Z').toLocal());
    expect(interview.end, DateTime.parse('2026-11-05T11:00:00Z').toLocal());
    expect(interview.online, isFalse);
    expect(interview.location, 'Qader Office, Giza');
    expect(interview.longitude, 31.235712);
    expect(interview.meetingUrl, 'https://meet.google.com/abc-defg-hij');
    expect(confirmed.slots, isEmpty);
  });
}
