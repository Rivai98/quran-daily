import 'failures.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;

  const factory Result.failure(AppFailure failure) = FailureResult<T>;

  bool get isSuccess;

  bool get isFailure => !isSuccess;

  T? get valueOrNull;

  AppFailure? get failureOrNull;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  });
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool get isSuccess => true;

  @override
  T? get valueOrNull => value;

  @override
  AppFailure? get failureOrNull => null;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return success(value);
  }
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final AppFailure failure;

  @override
  bool get isSuccess => false;

  @override
  T? get valueOrNull => null;

  @override
  AppFailure? get failureOrNull => failure;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return failure(this.failure);
  }
}
