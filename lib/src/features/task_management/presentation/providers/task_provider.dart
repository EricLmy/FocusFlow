import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/utils/result.dart' as core_result;
import '../../../../domain/entities/task.dart';
import '../../../../domain/repositories/task_repository.dart';
import '../../../../domain/state_machines/task_state_machine.dart';
import '../../../../domain/validators/task_validator.dart';
import '../../../../domain/services/task_service.dart';

/// 任务仓库Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DatabaseService.instance.taskRepository;
});

/// 任务服务Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return TaskService(taskRepository);
});

/// 任务列表状态类
class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 任务列表Notifier
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskService _taskService;

  TaskListNotifier(this._taskService) : super(const TaskListState());

  /// 加载所有任务
  Future<void> loadAllTasks({bool includeArchived = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _taskService.getAllTasks(includeArchived: includeArchived);
    
    if (result.isSuccess) {
      state = state.copyWith(
        tasks: result.getOrThrow(),
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: '加载任务失败: ${result.errorOrNull}',
      );
    }
  }

  /// 加载本周任务
  Future<void> loadThisWeekTasks({bool includeArchived = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _taskService.getAllTasks(includeArchived: includeArchived);
    
    if (result.isSuccess) {
      // 过滤本周任务
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final thisWeekTasks = result.getOrThrow().where((task) {
        return task.createdAt.isAfter(startOfWeek) && 
               task.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
      
      state = state.copyWith(
        tasks: thisWeekTasks,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: '加载本周任务失败: ${result.errorOrNull}',
      );
    }
  }

  /// 按日期范围加载任务
  Future<void> loadTasksByDateRange(
    DateTime startDate,
    DateTime endDate, {
    bool includeArchived = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _taskService.getAllTasks(includeArchived: includeArchived);
    
    if (result.isSuccess) {
      // 过滤指定日期范围的任务
      final filteredTasks = result.getOrThrow().where((task) {
        return task.createdAt.isAfter(startDate) && 
               task.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      state = state.copyWith(
        tasks: filteredTasks,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: '加载指定日期范围任务失败: ${result.errorOrNull}',
      );
    }
  }

  /// 创建任务
  Future<core_result.TaskResult<bool>> createTask(Task task) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _taskService.createTask(task);
    
    if (result.isSuccess) {
      // 重新加载任务列表
      await refreshTasks();
      return core_result.TaskResult.success(true);
    } else {
      state = state.copyWith(
        error: '创建任务失败: ${result.errorOrNull}',
        isLoading: false,
      );
      return core_result.TaskResult.failure(result.errorOrNull ?? '创建任务失败');
    }
  }

  /// 更新任务
  Future<core_result.TaskResult<bool>> updateTask(Task task) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _taskService.updateTask(task);
    
    if (result.isSuccess) {
      // 重新加载任务列表
      await refreshTasks();
      return core_result.TaskResult.success(true);
    } else {
      state = state.copyWith(
        error: '更新任务失败: ${result.errorOrNull}',
        isLoading: false,
      );
      return core_result.TaskResult.failure(result.errorOrNull ?? '更新任务失败');
    }
  }

  /// 删除任务
  Future<core_result.TaskResult<bool>> deleteTask(int taskId) async {
    final result = await _taskService.deleteTask(taskId);
    
    if (result.isSuccess) {
      // 从当前状态中移除任务
      final updatedTasks = state.tasks.where((task) => task.id != taskId).toList();
      state = state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(error: '删除任务失败: ${result.errorOrNull}');
    }
    
    return result;
  }

  /// 切换任务状态
  Future<core_result.Result<Task, String>> toggleTaskStatus(int taskId, TaskStatus newStatus) async {
    final result = await _taskService.toggleTaskStatus(taskId, newStatus);
    
    if (result.isSuccess) {
      // 重新加载任务列表以确保状态同步
      await refreshTasks();
    } else {
      state = state.copyWith(error: '切换任务状态失败: ${result.errorOrNull}');
    }
    
    return result;
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 刷新任务列表
  Future<void> refreshTasks() async {
    // 重新加载所有任务，让UI层根据筛选条件显示
    await loadAllTasks();
  }
}

/// 任务列表Provider
final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskListNotifier(taskService);
});

/// 过滤后的任务列表Provider
final filteredTasksProvider = Provider.family<List<Task>, Map<String, dynamic>>((ref, filters) {
  final taskListState = ref.watch(taskListProvider);
  final tasks = taskListState.tasks;
  
  return tasks.where((task) {
    // 状态筛选
    final selectedStatus = filters['status'] as String?;
    if (selectedStatus != null && selectedStatus != 'all') {
      final statusMap = {
        'pending': TaskStatus.pending,
        'inProgress': TaskStatus.inProgress,
        'completed': TaskStatus.completed,
        'cancelled': TaskStatus.cancelled,
      };
      if (task.status != statusMap[selectedStatus]) {
        return false;
      }
    }
    
    // 优先级筛选
    final selectedPriority = filters['priority'] as String?;
    if (selectedPriority != null && selectedPriority != 'all') {
      final priorityMap = {
        'high': TaskPriority.high,
        'medium': TaskPriority.medium,
        'low': TaskPriority.low,
        'urgent': TaskPriority.urgent,
      };
      if (task.priority != priorityMap[selectedPriority]) {
        return false;
      }
    }
    
    // 日期筛选
    final startDate = filters['startDate'] as DateTime?;
    final endDate = filters['endDate'] as DateTime?;
    
    if (startDate != null && task.createdAt.isBefore(startDate)) {
      return false;
    }
    if (endDate != null && task.createdAt.isAfter(endDate.add(const Duration(days: 1)))) {
      return false;
    }
    
    return true;
  }).toList();
});