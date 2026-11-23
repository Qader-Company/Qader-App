import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'notification_bell.dart';
import 'qader_asset.dart';

/// Top of the drawer pages: menu button, centered [title] and
/// notifications. Needs a [Scaffold] with a drawer above it.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.title});

  /// Already translated.
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'talent_menu'.tr(context: context),
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.zero,
        onPressed: () => Scaffold.of(context).openDrawer(),
        icon: const QaderAsset('menu', width: 14.6, height: 12.9),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      const NotificationBell(
        alignment: AlignmentDirectional.centerEnd,
        icon: QaderAsset('notification', width: 17.1, height: 17.9),
      ),
    ],
  );
}
