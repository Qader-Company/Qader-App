import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/base_state.dart';
import '../network/either.dart';
import '../network/failure.dart';

typedef PaginateFunc<T> =
    Future<Either<Failure, List<T>>> Function(
      int page,
      int limit, [
      Map<String, dynamic>? params,
    ]);

/// Mixin for cubits that need pagination support.
mixin PaginationMixin<T> on Cubit<BaseState<T>> {
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  int get pageSize => 15;
  final List<T> _items = [];

  List<T> get items => List.unmodifiable(_items);
  bool get hasMoreData => _hasMoreData;

  Future<void> loadFirstPage(
    PaginateFunc<T> fetchFunction, {
    Map<String, dynamic>? params,
  }) async {
    emit(state.copyWith(status: Status.loading));
    _items.clear();
    _currentPage = 1;
    _isLoadingMore = false;
    _hasMoreData = true;

    final result = await fetchFunction(_currentPage, pageSize, params);
    result.fold(
      (failure) {
        emit(
          state.copyWith(status: Status.failure, errorMessage: failure.message),
        );
      },
      (data) {
        _items.addAll(data);
        if (data.length >= pageSize) {
          _currentPage++;
        } else {
          _hasMoreData = false;
        }
        emit(
          state.copyWith(status: Status.success, items: List<T>.from(_items)),
        );
      },
    );
  }

  Future<void> loadNextPage(
    PaginateFunc<T> fetchFunction, {
    Map<String, dynamic>? params,
  }) async {
    if (!_hasMoreData || _isLoadingMore) {
      log(
        'Pagination: hasMoreData=$_hasMoreData, isLoadingMore=$_isLoadingMore',
      );
      return;
    }

    _isLoadingMore = true;
    if (_currentPage > 1) {
      emit(state.copyWith(status: Status.isLoadingMore));
    }

    final result = await fetchFunction(_currentPage, pageSize, params);
    result.fold(
      (failure) {
        _isLoadingMore = false;
        emit(
          state.copyWith(status: Status.failure, errorMessage: failure.message),
        );
      },
      (data) {
        _items.addAll(data);
        if (data.length >= pageSize) {
          _currentPage++;
        } else {
          _hasMoreData = false;
        }
        _isLoadingMore = false;
        emit(
          state.copyWith(status: Status.success, items: List<T>.from(_items)),
        );
      },
    );
  }

  void resetPagination() {
    _items.clear();
    _currentPage = 1;
    _isLoadingMore = false;
    _hasMoreData = true;
  }
}
