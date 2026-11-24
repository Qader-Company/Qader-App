import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qader/app/push_navigation.dart';
import 'package:qader/core/notifications/push_notifications.dart';
import 'package:qader/core/router/app_router.dart';

PushMessage _push(Map<String, dynamic> data) => PushMessage(data: data);

GoRouter _router() => GoRouter(
  initialLocation: AppRouter.root,
  routes: [
    for (final path in [
      AppRouter.root,
      AppRouter.profileSetup,
      AppRouter.home,
      AppRouter.notifications,
      AppRouter.offers,
      '${AppRouter.offers}/:id',
    ])
      GoRoute(path: path, builder: (_, state) => Text(state.uri.path)),
  ],
);

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  test('push data maps like an in-app notification', () {
    // Same fields as GET /talent/notifications items.
    expect(
      pushRoute(_push({'type': 'hiring_offer_received', 'target_id': 13})),
      '/offers/13',
    );
    expect(pushRoute(_push({'type': 'hiring_item_cancelled'})), '/offers');
    expect(
      pushRoute(_push({'type': 'talent_application_accepted'})),
      AppRouter.home,
    );
    // Unknown or missing type (e.g. a maintenance test): the list.
    expect(
      pushRoute(_push({'source': 'maintenance-test'})),
      AppRouter.notifications,
    );
    expect(
      pushRoute(_push({'type': 'something_new', 'target_id': '4'})),
      AppRouter.notifications,
    );
  });

  testWidgets('a tap opens the target over the current screen', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(AppRouter.home);
    await tester.pumpAndSettle();

    openPushTarget(
      router,
      _push({'type': 'hiring_interview_proposed', 'target_id': '13'}),
      signedIn: true,
    );
    await tester.pumpAndSettle();
    // push keeps the URL; the offer screen is on top.
    expect(find.text('/offers/13'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('a launching tap waits for startup to settle', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    openPushTarget(
      router,
      _push({'type': 'hiring_offer_received', 'target_id': '9'}),
      signedIn: true,
    );
    await tester.pumpAndSettle();
    expect(_location(router), AppRouter.root);

    // Splash, then profile setup, then home: only then the offer opens.
    router.go(AppRouter.profileSetup);
    await tester.pumpAndSettle();
    expect(_location(router), AppRouter.profileSetup);
    router.go(AppRouter.home);
    await tester.pumpAndSettle();
    expect(find.text('/offers/9'), findsOneWidget);

    // Opened once: later navigation is left alone.
    router.go(AppRouter.notifications);
    await tester.pumpAndSettle();
    expect(_location(router), AppRouter.notifications);
  });

  testWidgets('signed out, a tap does nothing', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(AppRouter.home);
    await tester.pumpAndSettle();
    openPushTarget(
      router,
      _push({'type': 'hiring_offer_received', 'target_id': '9'}),
      signedIn: false,
    );
    await tester.pumpAndSettle();
    expect(_location(router), AppRouter.home);
  });
}
