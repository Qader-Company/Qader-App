import 'package:equatable/equatable.dart';
import 'pagination_model.dart';

/// Wraps a single-item API response.
class BaseOneResponse extends Equatable {
  final dynamic data;
  final String? message;
  final String? status;
  final bool? success;
  final num? statusCode;

  const BaseOneResponse({
    this.data,
    this.message,
    this.status,
    this.success,
    this.statusCode,
  });

  factory BaseOneResponse.fromJson(Map<String, dynamic> json) {
    return BaseOneResponse(
      data: json['data'],
      message: json['message'],
      status: json['status']?.toString(),
      success: json['success'],
      statusCode: json['statusCode'],
    );
  }

  @override
  List<Object?> get props => [data, message, status, success, statusCode];
}

/// Wraps a list API response with optional pagination.
class BaseListResponse extends Equatable {
  final List<dynamic>? data;
  final String? message;
  final String? status;
  final PaginationModel? pagination;
  final num? statusCode;

  const BaseListResponse({
    this.data,
    this.message,
    this.status,
    this.pagination,
    this.statusCode,
  });

  factory BaseListResponse.fromJson(Map<String, dynamic> json) {
    return BaseListResponse(
      data: json['data'] is List ? json['data'] : null,
      message: json['message'],
      status: json['status']?.toString(),
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
      statusCode: json['statusCode'],
    );
  }

  @override
  List<Object?> get props => [data, message, status, pagination, statusCode];
}

/// Wraps a delete/action response.
class BaseActionResponse extends Equatable {
  final bool? success;
  final String? message;
  final dynamic data;

  const BaseActionResponse({this.success, this.message, this.data});

  factory BaseActionResponse.fromJson(Map<String, dynamic> json) {
    return BaseActionResponse(
      data: json['data'],
      message: json['message'],
      success: json['success'],
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
