import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';

/// A failed load with a retry button.
class WorkspaceFailure extends StatelessWidget {
  const WorkspaceFailure({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// A translation key, or the server's own message.
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message.tr(context: context), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          DefaultButton.compact(
            text: 'auth_retry'.tr(context: context),
            onPressed: onRetry,
          ),
        ],
      ),
    ),
  );
}
