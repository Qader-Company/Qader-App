import 'package:equatable/equatable.dart';
import '../network/failure.dart';

enum Status { initial, loading, success, failure, isLoadingMore, custom }

extension BaseStateX<T> on BaseState<T> {
  bool get isInitial => status == Status.initial;
  bool get isLoading => status == Status.loading;
  bool get isSuccess => status == Status.success;
  bool get isFailure => status == Status.failure;
  bool get isLoadingMore => status == Status.isLoadingMore;
  bool get isCustom => status == Status.custom;
  bool get isEmpty => isSuccess && items.isEmpty;
  bool get hasData => data != null;
}

class BaseState<T> extends Equatable {
  final Status status;
  final String? errorMessage;
  final Failure? failure;
  final T? data;
  final List<T> items;
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;

  const BaseState({
    this.status = Status.initial,
    this.errorMessage,
    this.failure,
    this.data,
    this.items = const [],
    this.lastUpdated,
    this.metadata = const {},
  });

  BaseState<T> copyWith({
    Status? status,
    String? errorMessage,
    Failure? failure,
    T? data,
    List<T>? items,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return BaseState<T>(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      failure: failure ?? this.failure,
      data: data ?? this.data,
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    failure,
    data,
    items,
    lastUpdated,
    metadata,
  ];
}
