import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);
  final ApiConsumer _api;
  static const path = '/talent/notifications';

  @override
  Future<Either<Failure, NotificationPage>> loadNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    final data = await _data(
      path,
      query: {
        'page': page < 1 ? 1 : page,
        'per_page': perPage,
        // `1` passes Laravel's boolean rule; the string "true" does not.
        if (unreadOnly) 'unread_only': 1,
      },
    );
    return data.fold(
      Left.new,
      (data) => data['notifications'] is List
          ? Right(NotificationPage.fromJson(data))
          : const Left(ServerFailure(message: _invalid)),
    );
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    final data = await _data('$path/unread-count');
    return data.fold(Left.new, (data) {
      final count = data['unread_count'];
      return count is num && count >= 0
          ? Right(count.toInt())
          : const Left(ServerFailure(message: _invalid));
    });
  }

  @override
  Future<Either<Failure, void>> markRead(String id) =>
      _patch('$path/${Uri.encodeComponent(id)}/read');

  @override
  Future<Either<Failure, void>> markAllRead() => _patch('$path/read-all');

  static const _invalid = 'notifications_invalid_response';

  Future<Either<Failure, void>> _patch(String path) async {
    final result = await _api.patch<Object?>(path, fromJson: (raw) => raw);
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      final message = raw is Map ? raw['message'] : null;
      return Left(
        ServerFailure(
          message: message is String && message.trim().isNotEmpty
              ? message
              : 'notifications_action_failed',
        ),
      );
    }
    return const Right(null);
  }

  /// The `data` object of a successful response.
  Future<Either<Failure, Map<String, dynamic>>> _data(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _api.get<Object?>(
      path,
      queryParameters: query,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      return const Left(ServerFailure(message: _invalid));
    }
    return Right(Map<String, dynamic>.from(raw['data'] as Map));
  }
}
