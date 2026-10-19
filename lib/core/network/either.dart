/// A functional type representing a value of one of two possible types.
/// [Left] represents a failure, [Right] represents a success.
abstract class Either<L, R> {
  const Either();

  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return leftFn(value);
  }
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return rightFn(value);
  }
}

extension EitherExtensions<L, R> on Either<L, R> {
  bool get isError => this is Left<L, R>;
  bool get isSuccess => this is Right<L, R>;

  R getOrThrow() {
    if (this is Right<L, R>) return (this as Right<L, R>).value;
    throw Exception('Cannot get value from Left instance.');
  }

  L getErrorOrThrow() {
    if (this is Left<L, R>) return (this as Left<L, R>).value;
    throw Exception('Cannot get error from Right instance.');
  }

  R? getOrNull() {
    if (this is Right<L, R>) return (this as Right<L, R>).value;
    return null;
  }

  /// Transform the success value without unwrapping.
  Either<L, R2> mapRight<R2>(R2 Function(R value) transform) {
    if (this is Right<L, R>) {
      return Right(transform((this as Right<L, R>).value));
    }
    return Left((this as Left<L, R>).value);
  }

  /// Transform the failure value without unwrapping.
  Either<L2, R> mapLeft<L2>(L2 Function(L value) transform) {
    if (this is Left<L, R>) return Left(transform((this as Left<L, R>).value));
    return Right((this as Right<L, R>).value);
  }

  /// Pattern-match-style API — same as fold but with named params for clarity.
  T when<T>({
    required T Function(L failure) error,
    required T Function(R data) success,
  }) {
    return fold(error, success);
  }
}
