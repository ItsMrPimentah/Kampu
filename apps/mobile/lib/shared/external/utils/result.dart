/// The outcome of an operation that can fail in an expected way.
sealed class Result<Val, Err> {
  const Result();

  /// Creates a successful outcome.
  const factory Result.val(Val value) = Success<Val, Err>;

  /// Creates a failed outcome.
  const factory Result.err(Err error) = Failure<Val, Err>;

  /// Handles both possible outcomes and returns the selected branch's value.
  T when<T>({
    required T Function(Val value) val,
    required T Function(Err error) err,
  });
}

/// A successful result containing [value].
final class Success<Val, Err> extends Result<Val, Err> {
  /// Creates a successful result.
  const Success(this.value);

  /// The value returned by the operation.
  final Val value;

  @override
  T when<T>({
    required T Function(Val value) val,
    required T Function(Err error) err,
  }) => val(value);
}

/// A failed result containing [error].
final class Failure<Val, Err> extends Result<Val, Err> {
  /// Creates a failed result.
  const Failure(this.error);

  /// The expected failure returned by the operation.
  final Err error;

  @override
  T when<T>({
    required T Function(Val value) val,
    required T Function(Err error) err,
  }) => err(error);
}

/// The value returned by a successful operation without a meaningful payload.
final class Ok {
  /// Creates a successful void value.
  const Ok();
}
