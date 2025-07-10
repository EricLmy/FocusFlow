import '../entities/task.dart';

/// 任务仓库接口
/// 定义任务数据操作的抽象方法，遵循Clean Architecture的依赖倒置原则
abstract class TaskRepository {
  /// 获取所有任务
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getAllTasks({bool includeArchived = false});
  
  /// 根据ID获取任务
  /// [id] 任务ID
  /// 返回任务实例，如果不存在则返回null
  Future<Task?> getTaskById(int id);
  
  /// 创建新任务
  /// [task] 要创建的任务实例
  /// 返回创建后的任务（包含生成的ID）
  Future<Task> createTask(Task task);
  
  /// 更新任务
  /// [task] 要更新的任务实例
  /// 返回更新后的任务
  Future<Task> updateTask(Task task);
  
  /// 删除任务
  /// [id] 要删除的任务ID
  /// 返回是否删除成功
  Future<bool> deleteTask(int id);
  
  /// 批量删除任务
  /// [ids] 要删除的任务ID列表
  /// 返回成功删除的任务数量
  Future<int> deleteTasks(List<int> ids);
  
  /// 归档任务
  /// [id] 要归档的任务ID
  /// 返回是否归档成功
  Future<bool> archiveTask(int id);
  
  /// 取消归档任务
  /// [id] 要取消归档的任务ID
  /// 返回是否取消归档成功
  Future<bool> unarchiveTask(int id);
  
  /// 批量归档任务
  /// [ids] 要归档的任务ID列表
  /// 返回成功归档的任务数量
  Future<int> archiveTasks(List<int> ids);
  
  /// 更新任务状态
  /// [id] 任务ID
  /// [status] 新状态
  /// 返回是否更新成功
  Future<bool> updateTaskStatus(int id, TaskStatus status);
  
  /// 更新任务优先级
  /// [id] 任务ID
  /// [priority] 新优先级
  /// 返回是否更新成功
  Future<bool> updateTaskPriority(int id, TaskPriority priority);
  
  /// 添加任务实际用时
  /// [id] 任务ID
  /// [minutes] 要添加的分钟数
  /// 返回是否更新成功
  Future<bool> addActualMinutes(int id, int minutes);
  
  /// 更新任务排序
  /// [taskOrders] 任务ID和排序值的映射
  /// 返回是否更新成功
  Future<bool> updateTaskOrders(Map<int, int> taskOrders);
  
  /// 按状态筛选任务
  /// [status] 任务状态
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTasksByStatus(TaskStatus status, {bool includeArchived = false});
  
  /// 按优先级筛选任务
  /// [priority] 任务优先级
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTasksByPriority(TaskPriority priority, {bool includeArchived = false});
  
  /// 按分类筛选任务
  /// [category] 任务分类
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTasksByCategory(String category, {bool includeArchived = false});
  
  /// 按标签筛选任务
  /// [tag] 标签
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTasksByTag(String tag, {bool includeArchived = false});
  
  /// 搜索任务
  /// [query] 搜索关键词
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> searchTasks(String query, {bool includeArchived = false});
  
  /// 获取逾期任务
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getOverdueTasks({bool includeArchived = false});
  
  /// 获取即将到期的任务
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getDueSoonTasks({bool includeArchived = false});
  
  /// 获取今天的任务
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTodayTasks({bool includeArchived = false});
  
  /// 获取本周的任务
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getThisWeekTasks({bool includeArchived = false});
  
  /// 获取指定日期范围内的任务
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  /// [includeArchived] 是否包含已归档的任务
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {bool includeArchived = false}
  );
  
  /// 获取所有分类
  Future<List<String>> getAllCategories();
  
  /// 获取所有标签
  Future<List<String>> getAllTags();
  
  /// 获取任务统计信息
  Future<TaskStatistics> getTaskStatistics();
  
  /// 获取指定日期范围内的任务统计信息
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<TaskStatistics> getTaskStatisticsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// 导出任务数据
  /// [format] 导出格式（如 'json', 'csv'）
  /// [includeArchived] 是否包含已归档的任务
  Future<String> exportTasks(String format, {bool includeArchived = false});
  
  /// 导入任务数据
  /// [data] 要导入的数据
  /// [format] 数据格式
  /// 返回成功导入的任务数量
  Future<int> importTasks(String data, String format);
  
  /// 清空所有任务数据
  /// [includeArchived] 是否包含已归档的任务
  Future<bool> clearAllTasks({bool includeArchived = true});
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo();
}

/// 任务统计信息
class TaskStatistics {
  final int totalTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int cancelledTasks;
  final int archivedTasks;
  final int overdueTasks;
  final int dueSoonTasks;
  final double completionRate;
  final int totalEstimatedMinutes;
  final int totalActualMinutes;
  final double averageActualMinutes;
  final Map<TaskPriority, int> tasksByPriority;
  final Map<String, int> tasksByCategory;
  final Map<String, int> tasksByTag;
  final DateTime? oldestTaskDate;
  final DateTime? newestTaskDate;
  
  const TaskStatistics({
    required this.totalTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.cancelledTasks,
    required this.archivedTasks,
    required this.overdueTasks,
    required this.dueSoonTasks,
    required this.completionRate,
    required this.totalEstimatedMinutes,
    required this.totalActualMinutes,
    required this.averageActualMinutes,
    required this.tasksByPriority,
    required this.tasksByCategory,
    required this.tasksByTag,
    this.oldestTaskDate,
    this.newestTaskDate,
  });
  
  /// 从Map创建TaskStatistics实例
  factory TaskStatistics.fromMap(Map<String, dynamic> map) {
    return TaskStatistics(
      totalTasks: map['totalTasks'] as int,
      pendingTasks: map['pendingTasks'] as int,
      inProgressTasks: map['inProgressTasks'] as int,
      completedTasks: map['completedTasks'] as int,
      cancelledTasks: map['cancelledTasks'] as int,
      archivedTasks: map['archivedTasks'] as int,
      overdueTasks: map['overdueTasks'] as int,
      dueSoonTasks: map['dueSoonTasks'] as int,
      completionRate: map['completionRate'] as double,
      totalEstimatedMinutes: map['totalEstimatedMinutes'] as int,
      totalActualMinutes: map['totalActualMinutes'] as int,
      averageActualMinutes: map['averageActualMinutes'] as double,
      tasksByPriority: Map<TaskPriority, int>.from(
        (map['tasksByPriority'] as Map).map(
          (key, value) => MapEntry(TaskPriority.values[key as int], value as int),
        ),
      ),
      tasksByCategory: Map<String, int>.from(map['tasksByCategory'] as Map),
      tasksByTag: Map<String, int>.from(map['tasksByTag'] as Map),
      oldestTaskDate: map['oldestTaskDate'] != null 
          ? DateTime.parse(map['oldestTaskDate'] as String)
          : null,
      newestTaskDate: map['newestTaskDate'] != null 
          ? DateTime.parse(map['newestTaskDate'] as String)
          : null,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalTasks': totalTasks,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'completedTasks': completedTasks,
      'cancelledTasks': cancelledTasks,
      'archivedTasks': archivedTasks,
      'overdueTasks': overdueTasks,
      'dueSoonTasks': dueSoonTasks,
      'completionRate': completionRate,
      'totalEstimatedMinutes': totalEstimatedMinutes,
      'totalActualMinutes': totalActualMinutes,
      'averageActualMinutes': averageActualMinutes,
      'tasksByPriority': tasksByPriority.map(
        (key, value) => MapEntry(key.index, value),
      ),
      'tasksByCategory': tasksByCategory,
      'tasksByTag': tasksByTag,
      'oldestTaskDate': oldestTaskDate?.toIso8601String(),
      'newestTaskDate': newestTaskDate?.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'TaskStatistics(totalTasks: $totalTasks, completionRate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}