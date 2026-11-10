import '../../domain/talent_application.dart';

/// Sample data for the status screen previews (`/status-preview`), used when
/// no application is loaded. Preview data only: never real account data.
abstract final class StatusPreviewData {
  static final slots = [
    InterviewSlot(
      id: 1,
      start: DateTime(2026, 8, 4, 10),
      end: DateTime(2026, 8, 4, 11),
    ),
    InterviewSlot(
      id: 2,
      start: DateTime(2026, 8, 4, 10),
      end: DateTime(2026, 8, 4, 11),
      online: false,
      location: 'Alfardos , 6 of october',
    ),
  ];

  /// The interview shown on the confirmed / completed previews.
  static final bookedStart = DateTime(2026, 8, 7, 11);
  static final bookedEnd = DateTime(2026, 8, 7, 12);

  /// Previous rounds shown in "Interview History".
  static final history = [
    ApplicationInterview(
      round: 1,
      status: 'completed',
      start: DateTime(2026, 8, 4, 10),
    ),
    ApplicationInterview(
      round: 2,
      status: 'scheduled',
      start: DateTime(2026, 8, 4, 10),
      online: false,
      location: 'Alfardos , 6 of october',
    ),
  ];

  /// Reapply countdown on the rejected preview.
  static DateTime reapplyAt() =>
      DateTime.now().add(const Duration(days: 72, hours: 21));
}
