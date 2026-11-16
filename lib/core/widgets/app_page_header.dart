import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../helpers/feature_dialog.dart';
import '../resources/app_colors.dart';
import 'default_form_field.dart';
import 'qader_asset.dart';
import 'spaced_column.dart';

/// Top of the drawer pages: menu button, centered [title], notifications
/// and the search field. Needs a [Scaffold] with a drawer above it.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.title});

  /// Already translated.
  final String title;
  @override
  Widget build(BuildContext context) => SpacedColumn(
    children: [
      Row(
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
          IconButton(
            tooltip: 'talent_notifications'.tr(context: context),
            alignment: AlignmentDirectional.centerEnd,
            onPressed: () => showPendingFeature(context, 'notifications'),
            icon: const QaderAsset('notification', width: 17.1, height: 17.9),
          ),
        ],
      ),
      DefaultFormField(
        compact: true,
        hint: 'talent_search_requests_talent_companies'.tr(context: context),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.neutral500,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => showInfoDialog(
          context,
          titleKey: 'talent_search',
          messageKey: 'talent_search_pending',
        ),
      ),
    ],
  );
}
