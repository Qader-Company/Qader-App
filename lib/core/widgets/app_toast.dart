import 'package:flutter/material.dart';
import '../resources/app_colors.dart';

/// What a toast reports; sets its icon and colors.
enum ToastType { success, error, info }

/// The app's one short message ("toast"): a floating card at the bottom with
/// an icon, tinted by [type]. Replaces the previous one, so quick actions
/// never stack messages. [message] is already translated.
///
/// Every screen uses this instead of building a `SnackBar` (see AGENTS.md).
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (icon, background, border, foreground) = switch (type) {
    ToastType.success => (
      Icons.check_circle_rounded,
      AppColors.green50,
      AppColors.green100,
      AppColors.green700,
    ),
    ToastType.error => (
      Icons.error_rounded,
      AppColors.red50,
      AppColors.red100,
      AppColors.red600,
    ),
    ToastType.info => (
      Icons.info_rounded,
      AppColors.blueSoft,
      AppColors.blueBorder,
      AppColors.blueStrong,
    ),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: ValueKey('app-toast-${type.name}'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: Duration(seconds: type == ToastType.error ? 4 : 3),
        content: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow5,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
