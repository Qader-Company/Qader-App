import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../domain/entities/app_notification.dart';

/// `notifications_<key>` translated.
String nt(BuildContext context, String key) =>
    'notifications_$key'.tr(context: context);

/// Where tapping [notification] leads, or `null` to stay on the list.
///
/// `hiring_*` notifications point at a hiring item (`target_id`), shown by
/// the offer details screen; `talent_*` ones are about the talent's own
/// application and interview, shown on home. Unknown types stay put.
String? notificationRoute(AppNotification notification) {
  final type = notification.type;
  final target = notification.targetId;
  if (type.startsWith('hiring_')) {
    return target == null
        ? AppRouter.offers
        : '${AppRouter.offers}/${Uri.encodeComponent(target)}';
  }
  if (type.startsWith('talent_')) return AppRouter.home;
  return null;
}

/// An icon for the kind of event; new backend types get the plain bell.
IconData notificationIcon(String type) {
  if (type.contains('interview')) return Icons.event_outlined;
  if (type.contains('cancelled') ||
      type.contains('expired') ||
      type.contains('rejected')) {
    return Icons.highlight_off;
  }
  if (type.contains('on_hold')) return Icons.pause_circle_outline;
  if (type.contains('resumed')) return Icons.play_circle_outline;
  if (type.contains('decision') || type.contains('accepted')) {
    return Icons.task_alt;
  }
  if (type.contains('offer')) return Icons.work_outline;
  return Icons.notifications_none;
}
