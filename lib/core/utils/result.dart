/// Lightweight Result type so the data/domain layers never throw across
/// boundaries — repositories return [Result] and callers branch explicitly.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onError) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onError(failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Typed failure surface used across the app.
class Failure {
  const Failure(this.message, {this.type = FailureType.unknown, this.cause});

  final String message;
  final FailureType type;
  final Object? cause;

  factory Failure.network([Object? cause]) =>
      Failure('No internet connection.', type: FailureType.network, cause: cause);

  factory Failure.permission(String message) =>
      Failure(message, type: FailureType.permission);

  factory Failure.notFound([String message = 'Not found.']) =>
      Failure(message, type: FailureType.notFound);

  factory Failure.cache(Object? cause) =>
      Failure('Local storage error.', type: FailureType.cache, cause: cause);

  @override
  String toString() => 'Failure($type): $message';
}

enum FailureType { network, permission, notFound, cache, validation, unknown }
