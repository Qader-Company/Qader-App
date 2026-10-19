import 'failure.dart';

abstract class AppException implements Exception {
  final String? message;
  const AppException({this.message});
  Failure toFailure();

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException({super.message, this.statusCode});

  @override
  Failure toFailure() => ServerFailure(
    message: message ?? 'Server error occurred',
    statusCode: statusCode,
  );
}

class NetworkException extends AppException {
  const NetworkException({super.message});

  @override
  Failure toFailure() =>
      NetworkFailure(message: message ?? 'No internet connection');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message});

  @override
  Failure toFailure() =>
      UnauthorizedFailure(message: message ?? 'Unauthorized');
}

class CacheException extends AppException {
  const CacheException({super.message});

  @override
  Failure toFailure() =>
      CacheFailure(message: message ?? 'Cache error occurred');
}
