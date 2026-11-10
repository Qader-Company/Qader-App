import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import '../domain/application_status.dart';
export '../domain/application_status.dart';

String sc(BuildContext context, String en, String ar) =>
    context.locale.languageCode == 'ar' ? ar : en;

extension ApplicationStatusLabel on ApplicationStatus {
  String label(BuildContext context) => switch (this) {
    ApplicationStatus.slots => sc(
      context,
      'Interview Slot Required',
      'اختيار موعد المقابلة',
    ),
    ApplicationStatus.confirmed => sc(
      context,
      'Interview Confirmed',
      'تم تأكيد المقابلة',
    ),
    ApplicationStatus.completed => sc(
      context,
      'Interview Completed',
      'اكتملت المقابلة',
    ),
    ApplicationStatus.accepted => sc(context, 'Talent Accepted', 'تم قبولك'),
    ApplicationStatus.cancelled => sc(
      context,
      'Cancelled Interview Slots',
      'مواعيد مقابلة ملغاة',
    ),
    ApplicationStatus.newSlots => sc(
      context,
      'New Interview Slots',
      'مواعيد مقابلة جديدة',
    ),
    ApplicationStatus.rejected => sc(
      context,
      'Profile Rejected',
      'تم رفض الطلب',
    ),
    ApplicationStatus.rejectedAfterInterview => sc(
      context,
      'Rejected after interview',
      'الرفض بعد المقابلة',
    ),
  };
}
