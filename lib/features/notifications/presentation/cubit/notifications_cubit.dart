import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

const _keep = Object();

class NotificationsState {
  const NotificationsState({
    this.loading = false,
    this.loadingMore = false,
    this.busy = false,
    this.failure,
    this.items = const [],
    this.unreadOnly = false,
    this.page = 1,
    this.lastPage = 1,
  });

  /// The first page is loading (filter change or reload).
  final bool loading;

  /// The next page is loading; [items] stay on screen.
  final bool loadingMore;

  /// A mark-as-read request is in flight.
  final bool busy;
  final Failure? failure;
  final List<AppNotification> items;
  final bool unreadOnly;
  final int page, lastPage;

  bool get hasMore => page < lastPage;
  bool get hasUnread => items.any((item) => item.unread);

  NotificationsState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? busy,
    Object? failure = _keep,
    List<AppNotification>? items,
    bool? unreadOnly,
    int? page,
    int? lastPage,
  }) => NotificationsState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    busy: busy ?? this.busy,
    failure: identical(failure, _keep) ? this.failure : failure as Failure?,
    items: items ?? this.items,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
  );
}

/// The notifications list: pages are appended as the talent scrolls; after
/// marking as read the list is reloaded from the server.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, {this.perPage = 20})
    : super(const NotificationsState(loading: true));
  final NotificationsRepository _repository;
  final int perPage;

  /// Only the newest first-page request may replace the list.
  int _request = 0;

  /// The first page again, keeping the filter.
  Future<void> load() async {
    final request = ++_request;
    emit(state.copyWith(loading: true, loadingMore: false, failure: null));
    final result = await _repository.loadNotifications(
      perPage: perPage,
      unreadOnly: state.unreadOnly,
    );
    if (isClosed || request != _request) return;
    emit(
      result.fold(
        (failure) => state.copyWith(loading: false, failure: failure),
        (page) => state.copyWith(
          loading: false,
          items: page.items,
          page: page.page,
          lastPage: page.lastPage,
        ),
      ),
    );
  }

  Future<void> showUnreadOnly(bool unreadOnly) {
    if (unreadOnly == state.unreadOnly) return Future.value();
    emit(state.copyWith(unreadOnly: unreadOnly, items: const []));
    return load();
  }

  /// Appends the next page; ignored while another load runs.
  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || state.loadingMore) return;
    final request = _request;
    emit(state.copyWith(loadingMore: true, failure: null));
    final result = await _repository.loadNotifications(
      page: state.page + 1,
      perPage: perPage,
      unreadOnly: state.unreadOnly,
    );
    // A reload or filter change started meanwhile: drop this page.
    if (isClosed || request != _request) return;
    emit(
      result.fold(
        (failure) => state.copyWith(loadingMore: false, failure: failure),
        (page) => state.copyWith(
          loadingMore: false,
          items: [
            ...state.items,
            for (final item in page.items)
              if (!state.items.any((old) => old.id == item.id)) item,
          ],
          page: page.page,
          lastPage: page.lastPage,
        ),
      ),
    );
  }

  /// Marks [notification] as read (if it is unread) and reloads.
  /// Returns the failure, if any; opening its target does not wait for it.
  Future<Failure?> markRead(AppNotification notification) async {
    if (!notification.unread) return null;
    return _run(() => _repository.markRead(notification.id));
  }

  Future<Failure?> markAllRead() => _run(_repository.markAllRead);

  Future<Failure?> _run(Future<Either<Failure, void>> Function() action) async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    final result = await action();
    if (isClosed) return null;
    emit(state.copyWith(busy: false));
    await load();
    return result.isError ? result.getErrorOrThrow() : null;
  }
}
