abstract class Failure {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  const Failure(this.message, {this.statusCode, this.responseData});

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? statusCode,
    dynamic responseData,
  }) : super(message, statusCode: statusCode, responseData: responseData);
}

class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required String message})
    : super(message, statusCode: 401);
}

class ValidationFailure extends Failure {
  final List<String> errors;
  const ValidationFailure({
    required String message,
    this.errors = const [],
    int? statusCode,
  }) : super(message, statusCode: statusCode);
}

class UnknownFailure extends Failure {
  const UnknownFailure({required String message}) : super(message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required String message}) : super(message);
}
