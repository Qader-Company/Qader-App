import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/notifications/domain/entities/app_notification.dart';
import 'package:qader/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:qader/features/notifications/presentation/cubit/notification_badge_controller.dart';
import 'package:qader/features/notifications/presentation/cubit/notifications_cubit.dart';

AppNotification _item(String id, {bool read = false}) => AppNotification(
  id: id,
  type: 'hiring_offer_received',
  title: 'Offer $id',
  body: '',
  targetId: id,
  readAt: read ? DateTime(2026, 11, 23) : null,
);

/// Two pages of two; reading marks items as read on the "server".
class _Repo extends Fake implements NotificationsRepository {
  final read = <String>{};
  final calls = <String>[];
  Failure? failure;
  int count = 3;

  List<AppNotification> get _all => [
    for (final id in ['1', '2', '3', '4'])
      _item(id, read: read.contains(id) || id == '4'),
  ];

  @override
  Future<Either<Failure, NotificationPage>> loadNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    calls.add('page $page${unreadOnly ? ' unread' : ''}');
    final items = [
      for (final item in _all)
        if (!unreadOnly || item.unread) item,
    ];
    final last = (items.length / perPage).ceil().clamp(1, 99);
    return Right(
      NotificationPage(
        items: items.skip((page - 1) * perPage).take(perPage).toList(),
        page: page,
        lastPage: last,
        total: items.length,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    calls.add('read $id');
    if (failure case final failure?) return Left(failure);
    read.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    calls.add('read all');
    read.addAll(['1', '2', '3']);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    calls.add('count');
    return Right(count);
  }
}

void main() {
  test('pages are appended until the last one', () async {
    final repo = _Repo();
    final cubit = NotificationsCubit(repo, perPage: 2);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.items.map((item) => item.id), ['1', '2']);
    expect(cubit.state.hasMore, isTrue);
    await cubit.loadMore();
    expect(cubit.state.items.map((item) => item.id), ['1', '2', '3', '4']);
    expect(cubit.state.hasMore, isFalse);
    await cubit.loadMore();
    expect(repo.calls, ['page 1', 'page 2']);
  });

  test('unread filter, mark as read and mark all reload the list', () async {
    final repo = _Repo();
    final cubit = NotificationsCubit(repo, perPage: 10);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.showUnreadOnly(true);
    expect(cubit.state.items.map((item) => item.id), ['1', '2', '3']);

    expect(await cubit.markRead(cubit.state.items.first), isNull);
    expect(cubit.state.items.map((item) => item.id), ['2', '3']);
    // Already read: nothing is sent.
    expect(await cubit.markRead(_item('4', read: true)), isNull);
    expect(repo.calls.where((call) => call == 'read 4'), isEmpty);

    repo.failure = const ServerFailure(message: 'Not found.');
    expect(
      (await cubit.markRead(cubit.state.items.first))?.message,
      'Not found.',
    );
    expect(cubit.state.busy, isFalse);

    expect(await cubit.markAllRead(), isNull);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.hasUnread, isFalse);
  });

  test('the badge counts only for a signed-in talent', () async {
    final repo = _Repo();
    var signedIn = false;
    final badge = NotificationBadgeController(repo, isSignedIn: () => signedIn);
    addTearDown(badge.dispose);
    await badge.refresh();
    expect(badge.enabled, isFalse);
    expect(badge.unreadCount.value, 0);
    expect(repo.calls, isEmpty);

    signedIn = true;
    await badge.refresh();
    expect(badge.unreadCount.value, 3);

    // Signing out clears it.
    signedIn = false;
    await badge.refresh();
    expect(badge.unreadCount.value, 0);
  });
}
