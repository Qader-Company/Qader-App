import '../../../../core/widgets/text_direction_of.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../notification_target.dart';

/// One notification: icon, title, body and time; unread ones are tinted and
/// marked with a dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.unread;
    final created = notification.createdAt;
    return Material(
      color: unread ? AppColors.paleBlue : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unread ? AppColors.blueBorder : AppColors.neutral200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: unread ? AppColors.blueSoft : AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificationIcon(notification.type),
                  size: 20,
                  color: unread ? AppColors.primary : AppColors.neutral600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      textDirection: textDirectionOf(
                        notification.title,
                        Directionality.of(context),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.neutral900,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        textDirection: textDirectionOf(
                          notification.body,
                          Directionality.of(context),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                    if (created != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        DateFormat(
                          'd MMM, h:mm a',
                          context.locale.toString(),
                        ).format(created),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (unread)
                Container(
                  key: const ValueKey('notification-unread-dot'),
                  margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
