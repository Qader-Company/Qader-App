import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/maybe_read.dart';
import '../helpers/feature_dialog.dart';
import '../notifications/notification_badge.dart';
import '../resources/app_colors.dart';
import '../router/app_router.dart';

/// The header bell: shows the unread count and opens the notifications
/// screen for a signed-in talent ("not connected yet" otherwise).
class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.icon,
    this.alignment = Alignment.center,
  });
  final Widget icon;
  final AlignmentGeometry alignment;
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final NotificationBadge? _badge = context.maybeRead<NotificationBadge>();

  @override
  void initState() {
    super.initState();
    final badge = _badge;
    if (badge != null && badge.enabled) badge.refresh();
  }

  Future<void> _open() async {
    final badge = _badge;
    if (badge == null || !badge.enabled) {
      await showPendingFeature(context, 'notifications');
      return;
    }
    await context.push(AppRouter.notifications);
    // Opening or reading notifications changes the count.
    if (mounted) await badge.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return IconButton(
      tooltip: 'talent_notifications'.tr(context: context),
      alignment: widget.alignment,
      onPressed: _open,
      icon: badge == null
          ? widget.icon
          : ValueListenableBuilder<int>(
              valueListenable: badge.unreadCount,
              builder: (context, count, icon) => Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppColors.red500,
                textColor: AppColors.white,
                label: Text(count > 99 ? '99+' : '$count'),
                child: icon,
              ),
              child: widget.icon,
            ),
    );
  }
}
