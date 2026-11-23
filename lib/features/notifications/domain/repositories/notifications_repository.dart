import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/app_notification.dart';

/// The talent's in-app notifications (`/talent/notifications`).
abstract class NotificationsRepository {
  Future<Either<Failure, NotificationPage>> loadNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  });

  Future<Either<Failure, int>> unreadCount();

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();
}
