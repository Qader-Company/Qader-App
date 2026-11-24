import 'package:flutter/material.dart';
import '../resources/app_colors.dart';

/// What a toast reports; sets its accent, icon and timing.
enum ToastType { success, error, info }

/// The app's one short message ("toast"): a white floating card at the
/// bottom with a colored accent on the start side, the type's icon in a
/// tinted circle, the [message] and a close button. A new toast replaces
/// the current one, so quick actions never stack messages. [message] is
/// already translated.
///
/// Every screen uses this instead of building a `SnackBar` (see AGENTS.md).
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (icon, accent, tint) = switch (type) {
    ToastType.success => (
      Icons.check_rounded,
      AppColors.green600,
      AppColors.green100,
    ),
    ToastType.error => (
      Icons.priority_high_rounded,
      AppColors.red600,
      AppColors.red100,
    ),
    ToastType.info => (
      Icons.info_outline_rounded,
      AppColors.blueStrong,
      AppColors.blueSoft,
    ),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: ValueKey('app-toast-${type.name}'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        dismissDirection: DismissDirection.horizontal,
        // Errors stay a little longer: they usually ask the user to do
        // something. Not more: the toast floats over the bottom buttons.
        duration: Duration(seconds: type == ToastType.error ? 4 : 3),
        content: _Toast(
          message: message,
          icon: icon,
          accent: accent,
          tint: tint,
          onClose: messenger.hideCurrentSnackBar,
        ),
      ),
    );
}

class _Toast extends StatelessWidget {
  const _Toast({
    required this.message,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.onClose,
  });
  final String message;
  final IconData icon;
  final Color accent, tint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow20,
            blurRadius: 24,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
          BoxShadow(color: AppColors.shadow5, blurRadius: 4),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The accent sits on the start side in both directions.
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 19 / 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      visualDensity: VisualDensity.compact,
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
