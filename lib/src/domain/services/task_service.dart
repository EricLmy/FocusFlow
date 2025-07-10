import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../state_machines/task_state_machine.dart';
import '../validators/task_validator.dart';
import '../../core/utils/result.dart' as core_result;

/// 任务服务
/// 封装复杂的任务业务逻辑，提供高级操作接口
class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  /// 获取所有任务
  Future<core_result.TaskResult<List<Task>>> getAllTasks({bool includeArchived = false}) async {
    try {
      final tasks = await _repository.getAllTasks(includeArchived: includeArchived);
      return core_result.Result.success(tasks);
    } catch (e) {
      return core_result.Result.failure('Failed to get all tasks: $e');
    }
  }

  /// 创建任务
  Future<core_result.TaskResult<Task>> createTask(Task task) async {
    try {
      // 验证任务数据
      final validationResult = TaskValidator.validateForCreation(task);
      if (validationResult.isFailure) {
        return core_result.Result.failure(validationResult.errorOrNull!);
      }

      // 创建任务
      final createdTask = await _repository.createTask(task);
      if (createdTask == null) {
        return core_result.Result.failure('Failed to create task in database');
      }

      return core_result.Result.success(createdTask);
    } catch (e) {
      return core_result.Result.failure('Failed to create task: $e');
    }
  }

  /// 更新任务
  Future<core_result.TaskResult<bool>> updateTask(Task task) async {
    try {
      // 验证任务数据
      final validationResult = TaskValidator.validateForUpdate(task);
      if (validationResult.isFailure) {
        return core_result.Result.failure(validationResult.errorOrNull!);
      }

      // 更新任务
      final updatedTask = await _repository.updateTask(task);
      if (updatedTask.id == null) {
        return core_result.Result.failure('Failed to update task in database');
      }

      return core_result.Result.success(true);
    } catch (e) {
      return core_result.Result.failure('Failed to update task: $e');
    }
  }

  /// 切换任务状态
  Future<core_result.TaskResult<Task>> toggleTaskStatus(int taskId, TaskStatus newStatus) async {
    try {
      // 获取当前任务
      final currentTask = await _repository.getTaskById(taskId);
      if (currentTask == null) {
        return core_result.Result.failure('Task not found');
      }

      // 使用状态机进行状态转换
      final transitionResult = TaskStateMachine.transitionTo(
        task: currentTask,
        newStatus: newStatus,
      );

      if (!transitionResult.isSuccess) {
        return core_result.Result.failure(transitionResult.errorMessage!);
      }

      final updatedTask = transitionResult.getOrThrow();

      // 更新数据库
      final finalUpdatedTask = await _repository.updateTask(updatedTask);
      if (finalUpdatedTask.id == null) {
        return core_result.Result.failure('Failed to update task status in database');
      }

      return core_result.Result.success(finalUpdatedTask);
    } catch (e) {
      return core_result.Result.failure('Failed to toggle task status: $e');
    }
  }

  /// 更新任务进度
  Future<core_result.TaskResult<Task>> updateTaskProgress(int taskId, double progress) async {
    try {
      // 验证进度值
      final progressValidation = TaskValidator.validateProgress(progress);
      if (progressValidation.isFailure) {
        return core_result.Result.failure(progressValidation.errorOrNull!);
      }

      // 获取当前任务
      final currentTask = await _repository.getTaskById(taskId);
      if (currentTask == null) {
        return core_result.Result.failure('Task not found');
      }

      // 根据进度推断状态
      final newStatus = TaskStateMachine.inferStatusFromProgress(progress);
      
      // 使用状态机进行转换
      final transitionResult = TaskStateMachine.transitionTo(
        task: currentTask,
        newStatus: newStatus,
        newProgress: progress,
      );

      if (!transitionResult.isSuccess) {
        return core_result.Result.failure(transitionResult.errorMessage!);
      }

      final updatedTask = transitionResult.getOrThrow();

      // 更新数据库
      final finalUpdatedTask = await _repository.updateTask(updatedTask);
      if (finalUpdatedTask.id == null) {
        return core_result.Result.failure('Failed to update task progress in database');
      }

      return core_result.Result.success(finalUpdatedTask);
    } catch (e) {
      return core_result.Result.failure('Failed to update task progress: $e');
    }
  }

  /// 批量更新任务状态
  Future<core_result.TaskResult<List<Task>>> batchUpdateStatus(
    List<int> taskIds,
    TaskStatus newStatus,
  ) async {
    try {
      if (taskIds.isEmpty) {
        return core_result.Result.failure('Task IDs list cannot be empty');
      }

      if (taskIds.length > 50) {
        return core_result.Result.failure('Cannot update more than 50 tasks at once');
      }

      final updatedTasks = <Task>[];
      final errors = <String>[];

      for (final taskId in taskIds) {
        final result = await toggleTaskStatus(taskId, newStatus);
        if (result.isSuccess) {
          updatedTasks.add(result.getOrThrow());
        } else {
          errors.add('Task $taskId: ${result.errorOrNull}');
        }
      }

      if (errors.isNotEmpty) {
        return core_result.Result.failure('Some tasks failed to update: ${errors.join(', ')}');
      }

      return core_result.Result.success(updatedTasks);
    } catch (e) {
      return core_result.Result.failure('Failed to batch update tasks: $e');
    }
  }

  /// 删除任务
  Future<core_result.TaskResult<bool>> deleteTask(int taskId) async {
    try {
      // 检查任务是否存在
      final task = await _repository.getTaskById(taskId);
      if (task == null) {
        return core_result.Result.failure('Task not found');
      }

      // 如果任务正在进行中，需要确认
      if (task.status == TaskStatus.inProgress) {
        return core_result.Result.failure('Cannot delete task in progress. Please complete or cancel it first.');
      }

      final success = await _repository.deleteTask(taskId);
      if (!success) {
        return core_result.Result.failure('Failed to delete task from database');
      }

      return core_result.Result.success(true);
    } catch (e) {
      return core_result.Result.failure('Failed to delete task: $e');
    }
  }

  /// 归档任务
  Future<core_result.TaskResult<Task>> archiveTask(int taskId) async {
    try {
      final currentTask = await _repository.getTaskById(taskId);
      if (currentTask == null) {
        return core_result.Result.failure('Task not found');
      }

      // 只有已完成或已取消的任务可以归档
      if (currentTask.status != TaskStatus.completed && 
          currentTask.status != TaskStatus.cancelled) {
        return core_result.Result.failure('Only completed or cancelled tasks can be archived');
      }

      final archivedTask = currentTask.copyWith(
        isArchived: true,
        updatedAt: DateTime.now(),
      );

      final finalArchivedTask = await _repository.updateTask(archivedTask);
      if (finalArchivedTask.id == null) {
        return core_result.Result.failure('Failed to archive task in database');
      }

      return core_result.Result.success(finalArchivedTask);
    } catch (e) {
      return core_result.Result.failure('Failed to archive task: $e');
    }
  }

  /// 恢复归档任务
  Future<core_result.TaskResult<Task>> unarchiveTask(int taskId) async {
    try {
      final currentTask = await _repository.getTaskById(taskId);
      if (currentTask == null) {
        return core_result.Result.failure('Task not found');
      }

      if (!currentTask.isArchived) {
        return core_result.Result.failure('Task is not archived');
      }

      final unarchivedTask = currentTask.copyWith(
        isArchived: false,
        updatedAt: DateTime.now(),
      );

      final finalUnarchivedTask = await _repository.updateTask(unarchivedTask);
      if (finalUnarchivedTask.id == null) {
        return core_result.Result.failure('Failed to unarchive task in database');
      }

      return core_result.Result.success(finalUnarchivedTask);
    } catch (e) {
      return core_result.Result.failure('Failed to unarchive task: $e');
    }
  }

  /// 复制任务
  Future<core_result.TaskResult<Task>> duplicateTask(int taskId) async {
    try {
      final originalTask = await _repository.getTaskById(taskId);
      if (originalTask == null) {
        return core_result.Result.failure('Original task not found');
      }

      // 创建副本，重置状态和时间
      final duplicatedTask = originalTask.copyWith(
        id: null, // 新任务没有ID
        title: '${originalTask.title} (副本)',
        status: TaskStatus.pending,
        progress: 0.0,
        actualMinutes: 0,
        completedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createTask(duplicatedTask);
    } catch (e) {
      return core_result.Result.failure('Failed to duplicate task: $e');
    }
  }

  /// 获取任务统计信息
  Future<core_result.TaskResult<TaskStatistics>> getTaskStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final tasks = await _repository.getTasksByDateRange(
        startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate ?? DateTime.now(),
      );

      final statistics = await _repository.getTaskStatisticsByDateRange(
        startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate ?? DateTime.now(),
      );
      return core_result.Result.success(statistics);
    } catch (e) {
      return core_result.Result.failure('Failed to get task statistics: $e');
    }
  }
}