import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// 任务仓库实现类
/// 实现TaskRepository接口，提供具体的数据库操作逻辑
class TaskRepositoryImpl implements TaskRepository {
  final DatabaseHelper _databaseHelper;
  
  TaskRepositoryImpl(this._databaseHelper);
  
  @override
  Future<List<Task>> getAllTasks({bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final whereClause = includeArchived ? null : 'isArchived = ?';
    final whereArgs = includeArchived ? null : [0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<Task?> getTaskById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Task.fromDatabaseMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<Task> createTask(Task task) async {
    final db = await _databaseHelper.database;
    final taskMap = task.toDatabaseMap();
    taskMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('tasks', taskMap);
    return task.copyWith(id: id);
  }
  
  @override
  Future<Task> updateTask(Task task) async {
    final db = await _databaseHelper.database;
    final taskMap = task.toDatabaseMap();
    taskMap['updatedAt'] = DateTime.now().toIso8601String();
    
    await db.update(
      'tasks',
      taskMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );
    
    return task.copyWith(updatedAt: DateTime.now());
  }
  
  @override
  Future<bool> deleteTask(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<int> deleteTasks(List<int> ids) async {
    if (ids.isEmpty) return 0;
    
    final db = await _databaseHelper.database;
    final placeholders = ids.map((_) => '?').join(',');
    
    return await db.delete(
      'tasks',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
  
  @override
  Future<bool> archiveTask(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.update(
      'tasks',
      {
        'isArchived': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<bool> unarchiveTask(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.update(
      'tasks',
      {
        'isArchived': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<int> archiveTasks(List<int> ids) async {
    if (ids.isEmpty) return 0;
    
    final db = await _databaseHelper.database;
    final placeholders = ids.map((_) => '?').join(',');
    
    return await db.update(
      'tasks',
      {
        'isArchived': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
  
  @override
  Future<bool> updateTaskStatus(int id, TaskStatus status) async {
    final db = await _databaseHelper.database;
    final count = await db.update(
      'tasks',
      {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<bool> updateTaskPriority(int id, TaskPriority priority) async {
    final db = await _databaseHelper.database;
    final count = await db.update(
      'tasks',
      {
        'priority': priority.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<bool> addActualMinutes(int id, int minutes) async {
    final db = await _databaseHelper.database;
    final count = await db.rawUpdate(
      'UPDATE tasks SET actual_minutes = actual_minutes + ?, updated_at = ? WHERE id = ?',
      [minutes, DateTime.now().toIso8601String(), id],
    );
    return count > 0;
  }
  
  @override
  Future<bool> updateTaskOrders(Map<int, int> taskOrders) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      for (final entry in taskOrders.entries) {
        await txn.update(
          'tasks',
          {
            'sortOrder': entry.value,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
    });
    
    return true;
  }
  
  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status, {bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final whereClause = includeArchived 
        ? 'status = ?' 
        : 'status = ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [status.name] 
        : [status.name, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByPriority(TaskPriority priority, {bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final whereClause = includeArchived 
        ? 'priority = ?' 
        : 'priority = ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [priority.index] 
        : [priority.index, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByCategory(String category, {bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final whereClause = includeArchived 
        ? 'category = ?' 
        : 'category = ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [category] 
        : [category, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByTag(String tag, {bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final whereClause = includeArchived 
        ? 'tags LIKE ?' 
        : 'tags LIKE ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? ['%$tag%'] 
        : ['%$tag%', 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> searchTasks(String query, {bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final searchPattern = '%$query%';
    final whereClause = includeArchived 
        ? '(title LIKE ? OR description LIKE ?)' 
        : '(title LIKE ? OR description LIKE ?) AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [searchPattern, searchPattern] 
        : [searchPattern, searchPattern, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getOverdueTasks({bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final whereClause = includeArchived 
        ? 'dueDate IS NOT NULL AND dueDate < ? AND status != ?' 
        : 'dueDate IS NOT NULL AND dueDate < ? AND status != ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [now, TaskStatus.completed.name] 
        : [now, TaskStatus.completed.name, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dueDate ASC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getDueSoonTasks({bool includeArchived = false}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1)).toIso8601String();
    final nowStr = now.toIso8601String();
    
    final whereClause = includeArchived 
        ? 'dueDate IS NOT NULL AND dueDate >= ? AND dueDate <= ? AND status != ?' 
        : 'dueDate IS NOT NULL AND dueDate >= ? AND dueDate <= ? AND status != ? AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [nowStr, tomorrow, TaskStatus.completed.name] 
        : [nowStr, tomorrow, TaskStatus.completed.name, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dueDate ASC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTodayTasks({bool includeArchived = false}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getTasksByDateRange(startOfDay, endOfDay, includeArchived: includeArchived);
  }
  
  @override
  Future<List<Task>> getThisWeekTasks({bool includeArchived = false}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getTasksByDateRange(startOfWeek, endOfWeek, includeArchived: includeArchived);
  }
  
  @override
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {bool includeArchived = false}
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final whereClause = includeArchived 
        ? '((createdAt >= ? AND createdAt < ?) OR (dueDate >= ? AND dueDate < ?))' 
        : '((createdAt >= ? AND createdAt < ?) OR (dueDate >= ? AND dueDate < ?)) AND isArchived = ?';
    final whereArgs = includeArchived 
        ? [startStr, endStr, startStr, endStr] 
        : [startStr, endStr, startStr, endStr, 0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<String>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      columns: ['category'],
      distinct: true,
      where: 'category IS NOT NULL AND category != ""',
      orderBy: 'category ASC',
    );
    
    return maps.map((map) => map['category'] as String).toList();
  }
  
  @override
  Future<List<String>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      columns: ['tags'],
      where: 'tags IS NOT NULL AND tags != ""',
    );
    
    final Set<String> allTags = {};
    for (final map in maps) {
      final tagsStr = map['tags'] as String;
      final tags = tagsStr.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
      allTags.addAll(tags);
    }
    
    final tagList = allTags.toList();
    tagList.sort();
    return tagList;
  }
  
  @override
  Future<TaskStatistics> getTaskStatistics() async {
    final db = await _databaseHelper.database;
    
    // 获取基本统计
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final totalTasks = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE status = ?', [TaskStatus.pending.name]);
    final pendingTasks = Sqflite.firstIntValue(pendingResult) ?? 0;
    
    final inProgressResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE status = ?', [TaskStatus.inProgress.name]);
    final inProgressTasks = Sqflite.firstIntValue(inProgressResult) ?? 0;
    
    final completedResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE status = ?', [TaskStatus.completed.name]);
    final completedTasks = Sqflite.firstIntValue(completedResult) ?? 0;
    
    final cancelledResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE status = ?', [TaskStatus.cancelled.name]);
    final cancelledTasks = Sqflite.firstIntValue(cancelledResult) ?? 0;
    
    final archivedResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE isArchived = 1');
    final archivedTasks = Sqflite.firstIntValue(archivedResult) ?? 0;
    
    // 获取逾期和即将到期的任务数量
    final now = DateTime.now().toIso8601String();
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE dueDate IS NOT NULL AND dueDate < ? AND status != ?',
      [now, TaskStatus.completed.name],
    );
    final overdueTasks = Sqflite.firstIntValue(overdueResult) ?? 0;
    
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String();
    final dueSoonResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE dueDate IS NOT NULL AND dueDate >= ? AND dueDate <= ? AND status != ?',
      [now, tomorrow, TaskStatus.completed.name],
    );
    final dueSoonTasks = Sqflite.firstIntValue(dueSoonResult) ?? 0;
    
    // 计算完成率
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    
    // 获取时间统计
    final timeResult = await db.rawQuery(
      'SELECT SUM(estimatedMinutes) as totalEstimated, SUM(actualMinutes) as totalActual, AVG(actualMinutes) as avgActual FROM tasks',
    );
    final timeMap = timeResult.first;
    final totalEstimatedMinutes = (timeMap['totalEstimated'] as num?)?.toInt() ?? 0;
    final totalActualMinutes = (timeMap['totalActual'] as num?)?.toInt() ?? 0;
    final averageActualMinutes = (timeMap['avgActual'] as num?)?.toDouble() ?? 0.0;
    
    // 获取按优先级分组的统计
    final priorityStats = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE priority = ?',
        [priority.index],
      );
      priorityStats[priority] = Sqflite.firstIntValue(result) ?? 0;
    }
    
    // 获取按分类分组的统计
    final categoryResult = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM tasks WHERE category IS NOT NULL AND category != "" GROUP BY category',
    );
    final tasksByCategory = <String, int>{};
    for (final map in categoryResult) {
      tasksByCategory[map['category'] as String] = map['count'] as int;
    }
    
    // 获取按标签分组的统计（简化处理）
    final tasksByTag = <String, int>{}; // 这里可以进一步实现标签统计逻辑
    
    // 获取最早和最新任务日期
    final dateResult = await db.rawQuery(
      'SELECT MIN(createdAt) as oldest, MAX(createdAt) as newest FROM tasks',
    );
    final dateMap = dateResult.first;
    final oldestTaskDate = dateMap['oldest'] != null 
        ? DateTime.parse(dateMap['oldest'] as String) 
        : null;
    final newestTaskDate = dateMap['newest'] != null 
        ? DateTime.parse(dateMap['newest'] as String) 
        : null;
    
    return TaskStatistics(
      totalTasks: totalTasks,
      pendingTasks: pendingTasks,
      inProgressTasks: inProgressTasks,
      completedTasks: completedTasks,
      cancelledTasks: cancelledTasks,
      archivedTasks: archivedTasks,
      overdueTasks: overdueTasks,
      dueSoonTasks: dueSoonTasks,
      completionRate: completionRate,
      totalEstimatedMinutes: totalEstimatedMinutes,
      totalActualMinutes: totalActualMinutes,
      averageActualMinutes: averageActualMinutes,
      tasksByPriority: priorityStats,
      tasksByCategory: tasksByCategory,
      tasksByTag: tasksByTag,
      oldestTaskDate: oldestTaskDate,
      newestTaskDate: newestTaskDate,
    );
  }
  
  @override
  Future<TaskStatistics> getTaskStatisticsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    
    // 获取日期范围内的基本统计
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final totalTasks = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), TaskStatus.pending.name],
    );
    final pendingTasks = Sqflite.firstIntValue(pendingResult) ?? 0;
    
    final inProgressResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), TaskStatus.inProgress.name],
    );
    final inProgressTasks = Sqflite.firstIntValue(inProgressResult) ?? 0;
    
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), TaskStatus.completed.name],
    );
    final completedTasks = Sqflite.firstIntValue(completedResult) ?? 0;
    
    final cancelledResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), TaskStatus.cancelled.name],
    );
    final cancelledTasks = Sqflite.firstIntValue(cancelledResult) ?? 0;
    
    final archivedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND isArchived = 1',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final archivedTasks = Sqflite.firstIntValue(archivedResult) ?? 0;
    
    // 获取逾期和即将到期的任务数量（在指定日期范围内创建的）
    final now = DateTime.now().toIso8601String();
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND dueDate IS NOT NULL AND dueDate < ? AND status != ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), now, TaskStatus.completed.name],
    );
    final overdueTasks = Sqflite.firstIntValue(overdueResult) ?? 0;
    
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String();
    final dueSoonResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND dueDate IS NOT NULL AND dueDate >= ? AND dueDate <= ? AND status != ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), now, tomorrow, TaskStatus.completed.name],
    );
    final dueSoonTasks = Sqflite.firstIntValue(dueSoonResult) ?? 0;
    
    // 计算完成率
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    
    // 获取时间统计
    final timeResult = await db.rawQuery(
      'SELECT SUM(estimatedMinutes) as totalEstimated, SUM(actualMinutes) as totalActual, AVG(actualMinutes) as avgActual FROM tasks WHERE createdAt >= ? AND createdAt <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final timeMap = timeResult.first;
    final totalEstimatedMinutes = (timeMap['totalEstimated'] as num?)?.toInt() ?? 0;
    final totalActualMinutes = (timeMap['totalActual'] as num?)?.toInt() ?? 0;
    final averageActualMinutes = (timeMap['avgActual'] as num?)?.toDouble() ?? 0.0;
    
    // 获取按优先级分组的统计
    final priorityStats = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND priority = ?',
        [startDate.toIso8601String(), endDate.toIso8601String(), priority.index],
      );
      priorityStats[priority] = Sqflite.firstIntValue(result) ?? 0;
    }
    
    // 获取按分类分组的统计
    final categoryResult = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM tasks WHERE createdAt >= ? AND createdAt <= ? AND category IS NOT NULL AND category != "" GROUP BY category',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final tasksByCategory = <String, int>{};
    for (final map in categoryResult) {
      tasksByCategory[map['category'] as String] = map['count'] as int;
    }
    
    // 获取按标签分组的统计（简化处理）
    final tasksByTag = <String, int>{}; // 这里可以进一步实现标签统计逻辑
    
    // 获取最早和最新任务日期（在指定范围内）
    final dateResult = await db.rawQuery(
      'SELECT MIN(createdAt) as oldest, MAX(createdAt) as newest FROM tasks WHERE createdAt >= ? AND createdAt <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final dateMap = dateResult.first;
    final oldestTaskDate = dateMap['oldest'] != null 
        ? DateTime.parse(dateMap['oldest'] as String) 
        : null;
    final newestTaskDate = dateMap['newest'] != null 
        ? DateTime.parse(dateMap['newest'] as String) 
        : null;
    
    return TaskStatistics(
      totalTasks: totalTasks,
      pendingTasks: pendingTasks,
      inProgressTasks: inProgressTasks,
      completedTasks: completedTasks,
      cancelledTasks: cancelledTasks,
      archivedTasks: archivedTasks,
      overdueTasks: overdueTasks,
      dueSoonTasks: dueSoonTasks,
      completionRate: completionRate,
      totalEstimatedMinutes: totalEstimatedMinutes,
      totalActualMinutes: totalActualMinutes,
      averageActualMinutes: averageActualMinutes,
      tasksByPriority: priorityStats,
      tasksByCategory: tasksByCategory,
      tasksByTag: tasksByTag,
      oldestTaskDate: oldestTaskDate,
      newestTaskDate: newestTaskDate,
    );
  }
  
  @override
  Future<String> exportTasks(String format, {bool includeArchived = false}) async {
    final tasks = await getAllTasks(includeArchived: includeArchived);
    
    if (format.toLowerCase() == 'json') {
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      return tasksJson.toString();
    } else if (format.toLowerCase() == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('ID,Title,Description,Priority,Status,EstimatedMinutes,ActualMinutes,CreatedAt,DueDate,Category,Tags,IsArchived');
      
      for (final task in tasks) {
        buffer.writeln([
          task.id,
          '"${task.title.replaceAll('"', '""')}"',
          '"${task.description?.replaceAll('"', '""') ?? ''}"',
          task.priority.name,
          task.status.name,
          task.estimatedMinutes,
          task.actualMinutes,
          task.createdAt.toIso8601String(),
          task.dueDate?.toIso8601String() ?? '',
          task.category ?? '',
          task.tags.join(','),
          task.isArchived,
        ].join(','));
      }
      
      return buffer.toString();
    }
    
    throw UnsupportedError('Unsupported export format: $format');
  }
  
  @override
  Future<int> importTasks(String data, String format) async {
    // 这里可以实现导入逻辑
    // 由于复杂性，暂时返回0
    return 0;
  }
  
  @override
  Future<bool> clearAllTasks({bool includeArchived = true}) async {
    final db = await _databaseHelper.database;
    
    if (includeArchived) {
      await db.delete('tasks');
    } else {
      await db.delete('tasks', where: 'isArchived = ?', whereArgs: [0]);
    }
    
    return true;
  }
  
  @override
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    return await _databaseHelper.getDatabaseInfo();
  }
}