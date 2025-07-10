import '../entities/task.dart';

/// 任务状态机
/// 管理任务状态转换的业务逻辑，确保状态变更的一致性
class TaskStateMachine {
  /// 验证状态转换是否合法
  static bool canTransitionTo(TaskStatus from, TaskStatus to) {
    switch (from) {
      case TaskStatus.pending:
        // 待办状态可以转换为进行中、已完成、已取消
        return to == TaskStatus.inProgress || 
               to == TaskStatus.completed || 
               to == TaskStatus.cancelled;
      
      case TaskStatus.inProgress:
        // 进行中状态可以转换为已完成、已取消，或回到待办
        return to == TaskStatus.completed || 
               to == TaskStatus.cancelled ||
               to == TaskStatus.pending;
      
      case TaskStatus.completed:
        // 已完成状态可以重新激活为待办或进行中
        return to == TaskStatus.pending || 
               to == TaskStatus.inProgress;
      
      case TaskStatus.cancelled:
        // 已取消状态可以重新激活为待办
        return to == TaskStatus.pending;
    }
  }

  /// 根据进度自动推断状态
  static TaskStatus inferStatusFromProgress(double progress) {
    if (progress <= 0.0) {
      return TaskStatus.pending;
    } else if (progress >= 1.0) {
      return TaskStatus.completed;
    } else {
      return TaskStatus.inProgress;
    }
  }

  /// 根据状态推断进度范围
  static (double min, double max) getProgressRangeForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return (0.0, 0.0);
      case TaskStatus.inProgress:
        return (0.01, 0.99);
      case TaskStatus.completed:
        return (1.0, 1.0);
      case TaskStatus.cancelled:
        return (0.0, 1.0); // 取消状态可以有任意进度
    }
  }

  /// 执行状态转换并同步进度
  static TaskTransitionResult transitionTo({
    required Task task,
    required TaskStatus newStatus,
    double? newProgress,
  }) {
    // 验证状态转换是否合法
    if (!canTransitionTo(task.status, newStatus)) {
      return TaskTransitionResult.failure(
        'Invalid state transition from ${task.status} to $newStatus'
      );
    }

    // 确定最终进度值
    double finalProgress;
    if (newProgress != null) {
      finalProgress = newProgress.clamp(0.0, 1.0);
    } else {
      // 根据新状态自动设置进度
      switch (newStatus) {
        case TaskStatus.pending:
          finalProgress = 0.0;
          break;
        case TaskStatus.completed:
          finalProgress = 1.0;
          break;
        case TaskStatus.inProgress:
          // 保持当前进度，但确保在合理范围内
          finalProgress = task.progress.clamp(0.01, 0.99);
          break;
        case TaskStatus.cancelled:
          // 保持当前进度
          finalProgress = task.progress;
          break;
      }
    }

    // 验证进度与状态的一致性
    final (minProgress, maxProgress) = getProgressRangeForStatus(newStatus);
    if (finalProgress < minProgress || finalProgress > maxProgress) {
      return TaskTransitionResult.failure(
        'Progress $finalProgress is not valid for status $newStatus'
      );
    }

    // 创建更新后的任务
    final updatedTask = task.copyWith(
      status: newStatus,
      progress: finalProgress,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    return TaskTransitionResult.success(updatedTask);
  }
}

/// 状态转换结果
class TaskTransitionResult {
  final bool isSuccess;
  final Task? task;
  final String? errorMessage;

  const TaskTransitionResult._(
    this.isSuccess,
    this.task,
    this.errorMessage,
  );

  factory TaskTransitionResult.success(Task task) {
    return TaskTransitionResult._(true, task, null);
  }

  factory TaskTransitionResult.failure(String message) {
    return TaskTransitionResult._(false, null, message);
  }

  /// 获取结果或抛出异常
  Task getOrThrow() {
    if (isSuccess && task != null) {
      return task!;
    }
    throw Exception(errorMessage ?? 'Unknown error');
  }
}