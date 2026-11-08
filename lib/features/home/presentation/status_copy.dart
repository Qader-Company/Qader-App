import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

String sc(BuildContext context, String en, String ar) =>
    context.locale.languageCode == 'ar' ? ar : en;

enum ApplicationStatus {
  slots,
  confirmed,
  completed,
  accepted,
  cancelled,
  newSlots,
  rejected,
  rejectedAfterInterview;

  String label(BuildContext context) => switch (this) {
    slots => sc(context, 'Interview Slot Required', 'اختيار موعد المقابلة'),
    confirmed => sc(context, 'Interview Confirmed', 'تم تأكيد المقابلة'),
    completed => sc(context, 'Interview Completed', 'اكتملت المقابلة'),
    accepted => sc(context, 'Talent Accepted', 'تم قبولك'),
    cancelled => sc(
      context,
      'Cancelled Interview Slots',
      'مواعيد مقابلة ملغاة',
    ),
    newSlots => sc(context, 'New Interview Slots', 'مواعيد مقابلة جديدة'),
    rejected => sc(context, 'Profile Rejected', 'تم رفض الطلب'),
    rejectedAfterInterview => sc(
      context,
      'Rejected after interview',
      'الرفض بعد المقابلة',
    ),
  };
}
