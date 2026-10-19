import 'package:equatable/equatable.dart';

class PaginationModel extends Equatable {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  const PaginationModel({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  bool get hasMore => (currentPage ?? 0) < (lastPage ?? 0);

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
      perPage: _parseInt(json['per_page']),
      total: _parseInt(json['total']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return num.tryParse(value.toString())?.toInt();
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total];
}
