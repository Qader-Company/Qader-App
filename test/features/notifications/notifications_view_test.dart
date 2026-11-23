import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/notifications/notification_badge.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/widgets/notification_bell.dart';
import 'package:qader/features/notifications/domain/entities/app_notification.dart';
import 'package:qader/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:qader/features/notifications/presentation/cubit/notification_badge_controller.dart';
import 'package:qader/features/notifications/presentation/view/notifications_view.dart';
import 'package:qader/features/notifications/presentation/widgets/notification_skeleton.dart';

class _Repo extends Fake implements NotificationsRepository {
  _Repo(this.items);
  List<AppNotification> items;
  final calls = <String>[];
  Failure? listFailure;

  /// Holds list requests until completed.
  Completer<void>? gate;

  @override
  Future<Either<Failure, NotificationPage>> loadNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    calls.add('list${unreadOnly ? ' unread' : ''}');
    await gate?.future;
    if (listFailure case final failure?) return Left(failure);
    return Right(
      NotificationPage(
        items: [
          for (final item in items)
            if (!unreadOnly || item.unread) item,
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, int>> unreadCount() async =>
      Right(items.where((item) => item.unread).length);

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    calls.add('read $id');
    items = [for (final item in items) item.id == id ? _copyRead(item) : item];
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    calls.add('read all');
    items = [for (final item in items) _copyRead(item)];
    return const Right(null);
  }

  static AppNotification _copyRead(AppNotification item) => AppNotification(
    id: item.id,
    type: item.type,
    title: item.title,
    body: item.body,
    targetId: item.targetId,
    readAt: DateTime(2026, 11, 23, 11),
    createdAt: item.createdAt,
  );
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

List<AppNotification> _sample() => [
  AppNotification(
    id: 'a29762c0',
    type: 'hiring_interview_proposed',
    title: 'Interview time proposed',
    body:
        'An interview time was proposed for Backend Developer '
        '(RI-2026-YQV3VMRE). Please respond.',
    targetId: '9',
    createdAt: DateTime(2026, 11, 23, 10, 26),
  ),
  AppNotification(
    id: 'b',
    type: 'hiring_offer_received',
    title: 'New job offer',
    body: 'Qader Technology sent you an offer for Backend Developer.',
    targetId: '9',
    readAt: DateTime(2026, 11, 22, 9),
    createdAt: DateTime(2026, 11, 22, 8, 40),
  ),
  AppNotification(
    id: 'c',
    type: 'something_new',
    title: 'Something new',
    body: '',
    createdAt: DateTime(2026, 11, 21, 15, 5),
  ),
];

void main() {
  testWidgets('bell count, list, open, mark all and empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    final repo = _Repo(_sample());
    final badge = NotificationBadgeController(repo, isSignedIn: () => true);
    addTearDown(badge.dispose);
    final opened = <String>[];
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<NotificationsRepository>.value(value: repo),
              RepositoryProvider<NotificationBadge>.value(value: badge),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                routerConfig: GoRouter(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) => const Scaffold(
                        body: Center(
                          child: NotificationBell(
                            icon: Icon(Icons.notifications_none),
                          ),
                        ),
                      ),
                    ),
                    GoRoute(
                      path: AppRouter.notifications,
                      builder: (_, _) => const NotificationsView(),
                    ),
                    GoRoute(
                      path: '${AppRouter.offers}/:id',
                      builder: (_, state) {
                        opened.add(state.uri.path);
                        return Scaffold(
                          appBar: AppBar(),
                          body: const Text('Offer screen'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Two unread notifications on the bell.
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Interview time proposed'), findsOneWidget);
    expect(find.text('New job offer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-unread-dot')),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/design_review/notifications_list.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    // A hiring notification: marked as read, then its offer opens.
    await tester.tap(find.text('Interview time proposed'));
    await tester.pumpAndSettle();
    expect(opened, ['/offers/9']);
    expect(repo.calls, contains('read a29762c0'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-unread-dot')),
      findsOneWidget,
    );

    // Unread filter, then mark all as read.
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Something new'), findsOneWidget);
    expect(find.text('New job offer'), findsNothing);
    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('read all'));
    expect(find.text('No unread notifications.'), findsOneWidget);

    // Back on the bell: the count is gone.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load can be retried', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final repo = _Repo(_sample())
      ..listFailure = const NetworkFailure(message: 'offline')
      ..gate = Completer();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
        startLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: RepositoryProvider<NotificationsRepository>.value(
          value: repo,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeManager.getTheme(context.locale),
              home: const NotificationsView(),
            ),
          ),
        ),
      ),
    );
    // Shimmer placeholders until the first page arrives.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NotificationListSkeleton), findsOneWidget);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationListSkeleton), findsNothing);
    expect(find.text("We couldn't load your notifications."), findsOneWidget);
    repo.listFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Interview time proposed'), findsOneWidget);
  });
}
