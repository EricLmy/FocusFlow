/// 通用结果类型，用于统一错误处理
/// 灵感来自Rust的Result类型
sealed class Result<T, E> {
  const Result();

  /// 创建成功结果
  factory Result.success(T value) = Success<T, E>;

  /// 创建失败结果
  factory Result.failure(E error) = Failure<T, E>;

  /// 是否为成功结果
  bool get isSuccess => this is Success<T, E>;

  /// 是否为失败结果
  bool get isFailure => this is Failure<T, E>;

  /// 获取成功值，如果失败则返回null
  T? get valueOrNull {
    return switch (this) {
      Success(value: final value) => value,
      Failure() => null,
    };
  }

  /// 获取错误，如果成功则返回null
  E? get errorOrNull {
    return switch (this) {
      Success() => null,
      Failure(error: final error) => error,
    };
  }

  /// 获取值或抛出异常
  T getOrThrow() {
    return switch (this) {
      Success(value: final value) => value,
      Failure(error: final error) => throw Exception(error.toString()),
    };
  }

  /// 获取值或返回默认值
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(value: final value) => value,
      Failure() => defaultValue,
    };
  }

  /// 映射成功值
  Result<U, E> map<U>(U Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => Result.success(mapper(value)),
      Failure(error: final error) => Result.failure(error),
    };
  }

  /// 映射错误值
  Result<T, F> mapError<F>(F Function(E) mapper) {
    return switch (this) {
      Success(value: final value) => Result.success(value),
      Failure(error: final error) => Result.failure(mapper(error)),
    };
  }

  /// 链式操作
  Result<U, E> flatMap<U>(Result<U, E> Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => mapper(value),
      Failure(error: final error) => Result.failure(error),
    };
  }

  /// 执行副作用操作
  Result<T, E> onSuccess(void Function(T) action) {
    if (this case Success(value: final value)) {
      action(value);
    }
    return this;
  }

  /// 执行错误处理
  Result<T, E> onFailure(void Function(E) action) {
    if (this case Failure(error: final error)) {
      action(error);
    }
    return this;
  }

  /// 折叠操作
  U fold<U>(U Function(T) onSuccess, U Function(E) onFailure) {
    return switch (this) {
      Success(value: final value) => onSuccess(value),
      Failure(error: final error) => onFailure(error),
    };
  }
}

/// 成功结果
final class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    return other is Success<T, E> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// 失败结果
final class Failure<T, E> extends Result<T, E> {
  final E error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) {
    return other is Failure<T, E> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

/// 扩展方法，用于异步操作
extension ResultAsync<T, E> on Future<Result<T, E>> {
  /// 异步映射成功值
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T) mapper) async {
    final result = await this;
    return switch (result) {
      Success(value: final value) => Result.success(await mapper(value)),
      Failure(error: final error) => Result.failure(error),
    };
  }

  /// 异步链式操作
  Future<Result<U, E>> flatMapAsync<U>(
    Future<Result<U, E>> Function(T) mapper,
  ) async {
    final result = await this;
    return switch (result) {
      Success(value: final value) => await mapper(value),
      Failure(error: final error) => Result.failure(error),
    };
  }
}

/// 便捷的类型别名
typedef TaskResult<T> = Result<T, String>;
typedef AsyncTaskResult<T> = Future<TaskResult<T>>;