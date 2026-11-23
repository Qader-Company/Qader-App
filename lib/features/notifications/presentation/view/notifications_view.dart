import 'package:flutter/material.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../cubit/notifications_cubit.dart';
import '../notification_target.dart';
import '../widgets/notification_skeleton.dart';
import '../widgets/notification_tile.dart';

/// The talent's notifications, newest first, paged as they scroll.
/// Tapping one marks it as read and opens what it is about.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final _cubit = NotificationsCubit(
    context.read<NotificationsRepository>(),
  )..load();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) _cubit.loadMore();
  }

  Future<void> _open(AppNotification notification) async {
    final route = notificationRoute(notification);
    final read = _cubit.markRead(notification);
    if (route == null) {
      _showFailure(await read);
      return;
    }
    await context.push(route);
    if (mounted) await _cubit.load();
  }

  Future<void> _markAllRead() async => _showFailure(await _cubit.markAllRead());

  void _showFailure(Failure? failure) {
    if (failure == null || !mounted) return;
    showAppToast(context, _message(failure), type: ToastType.error);
  }

  String _message(Failure failure) =>
      failure.message.startsWith('notifications_')
      ? nt(context, failure.message.substring('notifications_'.length))
      : failure.message;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    // Titles and bodies come localized from the backend.
    child: LocaleChangeListener(
      onChanged: _cubit.load,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          title: Text(
            nt(context, 'title'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              buildWhen: (a, b) =>
                  a.hasUnread != b.hasUnread || a.busy != b.busy,
              builder: (context, state) => IconButton(
                tooltip: nt(context, 'mark_all_read'),
                onPressed: state.hasUnread && !state.busy ? _markAllRead : null,
                icon: const Icon(Icons.done_all),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const _Filter(),
                  Expanded(
                    child: BlocBuilder<NotificationsCubit, NotificationsState>(
                      buildWhen: (a, b) =>
                          a.items != b.items ||
                          a.loading != b.loading ||
                          a.loadingMore != b.loadingMore ||
                          a.failure != b.failure,
                      builder: (context, state) => RefreshIndicator(
                        onRefresh: _cubit.load,
                        child: _list(context, state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _list(BuildContext context, NotificationsState state) {
    // Placeholder tiles on the first load and on every filter change or
    // reload, so an old list never looks current.
    if (state.loading) {
      return NotificationListSkeleton(
        count: state.items.isEmpty ? 5 : state.items.length.clamp(1, 5),
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        children: [
          if (state.failure != null)
            _LoadError(onRetry: _cubit.load)
          else
            _Empty(unreadOnly: state.unreadOnly),
        ],
      );
    }
    final footer = state.loadingMore || state.hasMore;
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: state.items.length + (footer ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const NotificationTileSkeleton();
        }
        final notification = state.items[index];
        return NotificationTile(
          key: ValueKey('notification-${notification.id}'),
          notification: notification,
          onTap: () => _open(notification),
        );
      },
    );
  }
}

/// All / Unread.
class _Filter extends StatelessWidget {
  const _Filter();
  @override
  Widget build(BuildContext context) =>
      BlocSelector<NotificationsCubit, NotificationsState, bool>(
        selector: (state) => state.unreadOnly,
        builder: (context, unreadOnly) {
          final cubit = context.read<NotificationsCubit>();
          Widget chip(String key, bool value) => ChoiceChip(
            label: Text(nt(context, key)),
            selected: unreadOnly == value,
            showCheckmark: false,
            selectedColor: AppColors.blueSoft,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: unreadOnly == value
                  ? AppColors.blueBorder
                  : AppColors.neutral200,
            ),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: unreadOnly == value
                  ? AppColors.primary
                  : AppColors.neutral700,
            ),
            onSelected: (_) => cubit.showUnreadOnly(value),
          );
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
            child: Row(
              children: [
                chip('all', false),
                const SizedBox(width: 8),
                chip('unread', true),
              ],
            ),
          );
        },
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.unreadOnly});
  final bool unreadOnly;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(
        Icons.notifications_none,
        size: 44,
        color: AppColors.neutral400,
      ),
      const SizedBox(height: 12),
      Text(
        nt(context, unreadOnly ? 'empty_unread' : 'empty'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
      ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(
        Icons.cloud_off_outlined,
        size: 40,
        color: AppColors.neutral500,
      ),
      const SizedBox(height: 12),
      Text(
        nt(context, 'load_failed'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 20 / 14),
      ),
      const SizedBox(height: 16),
      DefaultButton.compact(text: nt(context, 'try_again'), onPressed: onRetry),
    ],
  );
}
