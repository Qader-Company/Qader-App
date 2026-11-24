import 'dart:async';
import 'package:flutter/material.dart';
import '../resources/app_colors.dart';

/// What a toast reports; sets its accent, icon and timing.
enum ToastType { success, error, info }

OverlayEntry? _current;

/// The app's one short message ("toast"): a white card that slides in at
/// the top of the screen with a colored accent on the start side, the
/// type's icon in a tinted circle, the [message] and a close button.
///
/// It sits at the top so it never covers a screen's bottom buttons (most
/// screens end with their main action), and above dialogs. A new toast
/// replaces the current one, so quick actions never stack messages.
/// [message] is already translated.
///
/// Every screen uses this instead of building a `SnackBar` (see AGENTS.md).
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
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
  // The root overlay sits above the screen's own Directionality.
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  hideAppToast();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastHost(
      key: ValueKey('app-toast-${type.name}'),
      // Errors stay a little longer: they usually ask the user to do
      // something.
      duration: Duration(seconds: type == ToastType.error ? 4 : 3),
      onDismissed: () {
        if (identical(_current, entry)) hideAppToast();
      },
      builder: (close) => Directionality(
        textDirection: direction,
        child: _Toast(
          message: message,
          icon: icon,
          accent: accent,
          tint: tint,
          onClose: close,
        ),
      ),
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

/// Removes the current toast at once, if any.
void hideAppToast() {
  final entry = _current;
  _current = null;
  // Only this function removes toast entries, once each; `remove` is safe
  // even when the app (and its overlay) is already gone.
  entry
    ?..remove()
    ..dispose();
}

/// Slides the toast in, dismisses it after [duration], on close or on a
/// swipe, and owns the timer so it ends with the widget.
class _ToastHost extends StatefulWidget {
  const _ToastHost({
    super.key,
    required this.duration,
    required this.onDismissed,
    required this.builder,
  });
  final Duration duration;
  final VoidCallback onDismissed;
  final Widget Function(VoidCallback close) builder;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final _slide = Tween(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _controller,
              child: Dismissible(
                key: const ValueKey('app-toast-swipe'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismissed(),
                child: Material(
                  type: MaterialType.transparency,
                  child: widget.builder(_close),
                ),
              ),
            ),
          ),
        ),
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
