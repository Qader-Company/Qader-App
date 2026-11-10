import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import '../domain/application_status.dart';
export '../domain/application_status.dart';

extension ApplicationStatusLabel on ApplicationStatus {
  String label(BuildContext context) => switch (this) {
    ApplicationStatus.slots => 'status_interview_slot_required'.tr(
      context: context,
    ),
    ApplicationStatus.confirmed => 'status_interview_confirmed'.tr(
      context: context,
    ),
    ApplicationStatus.completed => 'status_interview_completed'.tr(
      context: context,
    ),
    ApplicationStatus.accepted => 'status_talent_accepted'.tr(context: context),
    ApplicationStatus.cancelled => 'status_cancelled_interview_slots'.tr(
      context: context,
    ),
    ApplicationStatus.newSlots => 'status_new_interview_slots'.tr(
      context: context,
    ),
    ApplicationStatus.rejected => 'status_profile_rejected'.tr(
      context: context,
    ),
    ApplicationStatus.rejectedAfterInterview =>
      'status_rejected_after_interview'.tr(context: context),
  };
}
