import 'package:go_router/go_router.dart';
import '../core/notifications/push_notifications.dart';
import '../core/router/app_router.dart';
import '../features/notifications/presentation/notification_target.dart';

/// Where tapping [message] leads: the screen its `type` and `target_id`
/// point to (the same fields as an in-app notification), otherwise the
/// notifications list, where every push also appears.
String pushRoute(PushMessage message) {
  final type = message.data['type']?.toString().trim() ?? '';
  final target = message.data['target_id']?.toString().trim() ?? '';
  return notificationRouteFor(type, target.isEmpty ? null : target) ??
      AppRouter.notifications;
}

/// Opens [message]'s screen on top of the current one.
///
/// When the tap launched the app, the splash and profile setup still
/// decide where the talent lands (and replace the stack when they move
/// on), so the push screen opens once the app settles on another screen.
/// Signed-out taps are ignored: these screens need a session.
void openPushTarget(
  GoRouter router,
  PushMessage message, {
  required bool signedIn,
}) {
  if (!signedIn) return;
  final route = pushRoute(message);
  const startup = {AppRouter.root, AppRouter.profileSetup};
  String location() => router.routerDelegate.currentConfiguration.uri.path;
  if (!startup.contains(location())) {
    router.push(route);
    return;
  }
  late void Function() listener;
  listener = () {
    if (startup.contains(location())) return;
    router.routerDelegate.removeListener(listener);
    router.push(route);
  };
  router.routerDelegate.addListener(listener);
}
