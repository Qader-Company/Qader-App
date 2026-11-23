import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/notifications/data/repositories/api_notifications_repository.dart';
import 'package:qader/features/notifications/domain/entities/app_notification.dart';
import 'package:qader/features/notifications/presentation/notification_target.dart';

/// Real `GET /talent/notifications` test-env response (Apidog).
Map<String, dynamic> _list() => {
  'success': true,
  'data': {
    'notifications': [
      {
        'id': 'a29762c0-3cb2-49bd-b862-ccabbfcce8cd',
        'type': 'hiring_interview_proposed',
        'title': 'Interview time proposed',
        'body':
            'An interview time was proposed for Backend Developer '
            '(RI-2026-YQV3VMRE). Please respond.',
        'target_id': 9,
        'read_at': null,
        'created_at': '2026-11-23T08:26:01+00:00',
      },
    ],
    'meta': {'current_page': 1, 'last_page': 1, 'per_page': 20, 'total': 1},
  },
};

class _Api extends Fake implements ApiConsumer {
  Object? reply;
  final gets = <(String, Map<String, dynamic>?)>[];
  final patches = <String>[];

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    gets.add((path, queryParameters));
    return Right(fromJson(reply));
  }

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    patches.add(path);
    return Right(fromJson(reply));
  }
}

void main() {
  test('lists notifications from the Apidog example', () async {
    final api = _Api()..reply = _list();
    final repository = ApiNotificationsRepository(api);
    final page = (await repository.loadNotifications()).getOrThrow();
    expect(api.gets.single.$1, '/talent/notifications');
    expect(api.gets.single.$2, {'page': 1, 'per_page': 20});
    expect(page.page, 1);
    expect(page.lastPage, 1);
    expect(page.total, 1);
    final item = page.items.single;
    expect(item.id, 'a29762c0-3cb2-49bd-b862-ccabbfcce8cd');
    expect(item.type, 'hiring_interview_proposed');
    expect(item.title, 'Interview time proposed');
    expect(item.targetId, '9');
    expect(item.unread, isTrue);
    expect(item.createdAt, DateTime.utc(2026, 11, 23, 8, 26, 1).toLocal());
    // A hiring notification opens its hiring item.
    expect(notificationRoute(item), '/offers/9');

    await repository.loadNotifications(page: 2, unreadOnly: true);
    expect(api.gets.last.$2, {'page': 2, 'per_page': 20, 'unread_only': 1});

    api.reply = {'success': true, 'data': <String, dynamic>{}};
    final invalid = await repository.loadNotifications();
    expect(invalid.getErrorOrThrow().message, 'notifications_invalid_response');
  });

  test('items without an id are skipped; odd fields do not crash', () {
    final page = NotificationPage.fromJson({
      'notifications': [
        {'type': 'x'},
        {
          'id': 'b',
          'type': null,
          'title': 5,
          'target_id': null,
          'read_at': '2026-11-23T09:00:00+00:00',
          'created_at': 'not a date',
        },
        'oops',
      ],
      'meta': {'current_page': '2', 'last_page': 3.0},
    });
    expect(page.items.map((item) => item.id), ['b']);
    expect(page.items.single.title, '5');
    expect(page.items.single.targetId, isNull);
    expect(page.items.single.unread, isFalse);
    expect(page.items.single.createdAt, isNull);
    expect(page.page, 2);
    expect(page.lastPage, 3);
  });

  test('unread count and mark as read', () async {
    final api = _Api()
      ..reply = {
        'success': true,
        'data': {'unread_count': 1},
      };
    final repository = ApiNotificationsRepository(api);
    expect((await repository.unreadCount()).getOrThrow(), 1);
    expect(api.gets.single.$1, '/talent/notifications/unread-count');

    api.reply = {'success': true, 'message': 'ok'};
    expect((await repository.markRead('a 1')).isSuccess, isTrue);
    expect((await repository.markAllRead()).isSuccess, isTrue);
    expect(api.patches, [
      '/talent/notifications/a%201/read',
      '/talent/notifications/read-all',
    ]);

    api.reply = {'success': false, 'message': 'Not found.'};
    expect(
      (await repository.markRead('x')).getErrorOrThrow().message,
      'Not found.',
    );
    api.reply = 'oops';
    expect(
      (await repository.markAllRead()).getErrorOrThrow().message,
      'notifications_action_failed',
    );
    expect(
      (await repository.unreadCount()).getErrorOrThrow().message,
      'notifications_invalid_response',
    );
  });

  test('taps lead to the right screen', () {
    AppNotification of(String type, {String? target}) => AppNotification(
      id: '1',
      type: type,
      title: '',
      body: '',
      targetId: target,
    );
    expect(
      notificationRoute(of('hiring_offer_received', target: '7')),
      '/offers/7',
    );
    expect(notificationRoute(of('hiring_item_cancelled')), '/offers');
    expect(notificationRoute(of('talent_interview_slots_available')), '/home');
    expect(notificationRoute(of('talent_application_accepted')), '/home');
    expect(notificationRoute(of('something_new')), isNull);
  });
}
