/// A sealed class representing the result of an operation.
///
/// It can either be a [Success] or a [Failure].
sealed class Result<T, E extends Exception> {
  const Result();
}

/// Represents a successful operation.
class Success<T, E extends Exception> extends Result<T, E> {
  /// Creates a success result holding the [value].
  const Success(this.value);

  /// The value returned by the successful operation.
  final T value;
}

/// Represents a failed operation.
class Failure<T, E extends Exception> extends Result<T, E> {
  /// Creates a failure result holding the [exception].
  const Failure(this.exception);

  /// The exception returned by the failed operation.
  final E exception;
}
