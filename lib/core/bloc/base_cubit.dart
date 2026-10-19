import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/either.dart';
import '../network/failure.dart';
import 'base_state.dart';

/// A reusable base Cubit that reduces boilerplate for common fetch patterns.
///
/// Usage:
/// ```dart
/// class UsersCubit extends BaseCubit<UserModel> {
///   final UserRepo _repo;
///   UsersCubit(this._repo) : super();
/// }
/// ```
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit() : super(const BaseState());

  /// Fetch a list of items and emit the appropriate state.
  Future<void> fetchList(
    Future<Either<Failure, List<T>>> Function() fetcher,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final result = await fetcher();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: Status.success,
          items: data,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  /// Fetch a single item and emit the appropriate state.
  Future<void> fetchSingle(
    Future<Either<Failure, T>> Function() fetcher,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final result = await fetcher();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: Status.success,
          data: data,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  /// Execute an action (post/put/delete) and emit the appropriate state.
  Future<void> execute<R>(
    Future<Either<Failure, R>> Function() action, {
    void Function(R data)? onSuccess,
  }) async {
    emit(state.copyWith(status: Status.loading));
    final result = await action();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (data) {
        onSuccess?.call(data);
        emit(state.copyWith(status: Status.success));
      },
    );
  }
}
