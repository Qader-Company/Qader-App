import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String titleKey,
  required String messageKey,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(titleKey.tr(context: context)),
    content: Text(messageKey.tr(context: context)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('confirm'.tr(context: context)),
      ),
    ],
  ),
);
Future<void> showPendingFeature(BuildContext context, String title) =>
    showInfoDialog(context, titleKey: title, messageKey: 'service_pending');
