import '../../core/database/database_helper.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/focus_record.dart';
import '../../domain/entities/draft.dart';
import '../../domain/entities/export_record.dart';
import 'local_data_source.dart';

/// 本地数据源实现类
/// 实现LocalDataSource接口，提供具体的SQLite数据库操作
class LocalDataSourceImpl implements LocalDataSource {
  final DatabaseHelper _databaseHelper;
  
  LocalDataSourceImpl(this._databaseHelper);
  
  // ==================== 任务相关操作 ====================
  
  @override
  Future<List<Task>> getAllTasks({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
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
      return Task.fromMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<Task> createTask(Task task) async {
    final db = await _databaseHelper.database;
    final taskMap = task.toMap();
    taskMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('tasks', taskMap);
    return task.copyWith(id: id);
  }
  
  @override
  Future<Task> updateTask(Task task) async {
    final db = await _databaseHelper.database;
    final taskMap = task.toMap();
    
    await db.update(
      'tasks',
      taskMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );
    
    return task;
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
  Future<Task> archiveTask(int id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tasks',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final task = await getTaskById(id);
    return task!;
  }
  
  @override
  Future<Task> unarchiveTask(int id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tasks',
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final task = await getTaskById(id);
    return task!;
  }
  
  @override
  Future<Task> updateTaskStatus(int id, TaskStatus status) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tasks',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final task = await getTaskById(id);
    return task!;
  }
  
  @override
  Future<Task> updateTaskPriority(int id, TaskPriority priority) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tasks',
      {'priority': priority.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final task = await getTaskById(id);
    return task!;
  }
  
  @override
  Future<Task> updateTaskActualMinutes(int id, int actualMinutes) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tasks',
      {'actual_minutes': actualMinutes},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final task = await getTaskById(id);
    return task!;
  }
  
  @override
  Future<bool> updateTasksOrder(List<int> taskIds) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (int i = 0; i < taskIds.length; i++) {
      batch.update(
        'tasks',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [taskIds[i]],
      );
    }
    
    await batch.commit();
    return true;
  }
  
  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'status = ? AND is_archived = ?',
      whereArgs: [status.name, 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByPriority(TaskPriority priority, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'priority = ? AND is_archived = ?',
      whereArgs: [priority.name, 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByCategory(String category, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category = ? AND is_archived = ?',
      whereArgs: [category, 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByTag(String tag, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'tags LIKE ? AND is_archived = ?',
      whereArgs: ['%$tag%', 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'created_at >= ? AND created_at < ? AND is_archived = ?',
      whereArgs: [startStr, endStr, 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> searchTasks(String query, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final searchPattern = '%$query%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: '(title LIKE ? OR description LIKE ? OR tags LIKE ?) AND is_archived = ?',
      whereArgs: [searchPattern, searchPattern, searchPattern, 0],
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getOverdueTasks({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date IS NOT NULL AND due_date < ? AND status != ? AND is_archived = ?',
      whereArgs: [now, TaskStatus.completed.name, 0],
      orderBy: 'due_date ASC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getDueSoonTasks({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1)).toIso8601String();
    final nowStr = now.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date IS NOT NULL AND due_date >= ? AND due_date <= ? AND status != ? AND is_archived = ?',
      whereArgs: [nowStr, tomorrow, TaskStatus.completed.name, 0],
      orderBy: 'due_date ASC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Task.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<Task>> getTodayTasks({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getTasksByDateRange(startOfDay, endOfDay, limit: limit, offset: offset);
  }
  
  @override
  Future<List<Task>> getThisWeekTasks({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getTasksByDateRange(startOfWeek, endOfWeek, limit: limit, offset: offset);
  }
  
  @override
  Future<List<String>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM tasks WHERE category IS NOT NULL AND category != "" AND is_archived = 0 ORDER BY category',
    );
    
    return maps.map((map) => map['category'] as String).toList();
  }
  
  @override
  Future<List<String>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT tags FROM tasks WHERE tags IS NOT NULL AND tags != "" AND is_archived = 0',
    );
    
    final Set<String> allTags = {};
    for (final map in maps) {
      final tagsStr = map['tags'] as String;
      final tags = tagsStr.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
      allTags.addAll(tags);
    }
    
    final sortedTags = allTags.toList()..sort();
    return sortedTags;
  }
  
  @override
  Future<bool> clearAllTasks() async {
    final db = await _databaseHelper.database;
    await db.delete('tasks');
    return true;
  }
  
  // ==================== 专注记录相关操作 ====================
  
  @override
  Future<List<FocusRecord>> getAllFocusRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromMap(map)).toList();
  }
  
  @override
  Future<FocusRecord?> getFocusRecordById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return FocusRecord.fromMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<FocusRecord> createFocusRecord(FocusRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toMap();
    recordMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('focus_records', recordMap);
    return record.copyWith(id: id);
  }
  
  @override
  Future<FocusRecord> updateFocusRecord(FocusRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toMap();
    
    await db.update(
      'focus_records',
      recordMap,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    
    return record;
  }
  
  @override
  Future<bool> deleteFocusRecord(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      'focus_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<int> deleteFocusRecords(List<int> ids) async {
    if (ids.isEmpty) return 0;
    
    final db = await _databaseHelper.database;
    final placeholders = ids.map((_) => '?').join(',');
    
    return await db.delete(
      'focus_records',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
  
  @override
  Future<FocusRecord?> getActiveFocusSession() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'status IN (?, ?)',
      whereArgs: [FocusSessionStatus.active.name, FocusSessionStatus.paused.name],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return FocusRecord.fromDatabaseMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<List<FocusRecord>> getFocusRecordsByTask(int taskId, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getFocusRecordsByStatus(FocusSessionStatus status, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getFocusRecordsByModeType(FocusModeType modeType, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'mode_type = ?',
      whereArgs: [modeType.name],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getFocusRecordsByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [startStr, endStr],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getTodayFocusRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getFocusRecordsByDateRange(startOfDay, endOfDay, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getThisWeekFocusRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getFocusRecordsByDateRange(startOfWeek, endOfWeek, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getThisMonthFocusRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return getFocusRecordsByDateRange(startOfMonth, endOfMonth, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getCompletedFocusRecords({int? limit, int? offset}) async {
    return getFocusRecordsByStatus(FocusSessionStatus.completed, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getInterruptedFocusRecords({int? limit, int? offset}) async {
    return getFocusRecordsByStatus(FocusSessionStatus.interrupted, limit: limit, offset: offset);
  }
  
  @override
  Future<int> cleanupOldFocusRecords(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'focus_records',
      where: 'start_time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<bool> clearAllFocusRecords() async {
    final db = await _databaseHelper.database;
    await db.delete('focus_records');
    return true;
  }
  
  // ==================== 草稿相关操作 ====================
  
  @override
  Future<List<Draft>> getAllDrafts({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      orderBy: 'save_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Draft.fromMap(map)).toList();
  }
  
  @override
  Future<Draft?> getDraftById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Draft.fromMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<Draft> createDraft(Draft draft) async {
    final db = await _databaseHelper.database;
    final draftMap = draft.toMap();
    draftMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('drafts', draftMap);
    return draft.copyWith(id: id);
  }
  
  @override
  Future<Draft> updateDraft(Draft draft) async {
    final db = await _databaseHelper.database;
    final draftMap = draft.toMap();
    
    await db.update(
      'drafts',
      draftMap,
      where: 'id = ?',
      whereArgs: [draft.id],
    );
    
    return draft;
  }
  
  @override
  Future<bool> deleteDraft(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      'drafts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<int> deleteDrafts(List<int> ids) async {
    if (ids.isEmpty) return 0;
    
    final db = await _databaseHelper.database;
    final placeholders = ids.map((_) => '?').join(',');
    
    return await db.delete(
      'drafts',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
  
  @override
  Future<List<Draft>> getLatestDrafts({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      orderBy: 'save_time DESC',
      limit: limit,
    );
    
    return maps.map((map) => Draft.fromMap(map)).toList();
  }
  
  @override
  Future<List<Draft>> searchDrafts(String query, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final searchPattern = '%$query%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      where: 'task_data LIKE ?',
      whereArgs: [searchPattern],
      orderBy: 'save_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Draft.fromMap(map)).toList();
  }
  
  @override
  Future<List<Draft>> getDraftsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      where: 'save_time >= ? AND save_time < ?',
      whereArgs: [startStr, endStr],
      orderBy: 'save_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => Draft.fromMap(map)).toList();
  }
  
  @override
  Future<List<Draft>> getTodayDrafts({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getDraftsByDateRange(startOfDay, endOfDay, limit: limit, offset: offset);
  }
  
  @override
  Future<List<Draft>> getThisWeekDrafts({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getDraftsByDateRange(startOfWeek, endOfWeek, limit: limit, offset: offset);
  }
  
  @override
  Future<int> cleanupOldDrafts(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'drafts',
      where: 'save_time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<List<Draft>> getEmptyDrafts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drafts',
      where: 'task_data IS NULL OR task_data = "" OR task_data = "{}"',
      orderBy: 'save_time DESC',
    );
    
    return maps.map((map) => Draft.fromMap(map)).toList();
  }
  
  @override
  Future<int> cleanupEmptyDrafts() async {
    final db = await _databaseHelper.database;
    
    return await db.delete(
      'drafts',
      where: 'task_data IS NULL OR task_data = "" OR task_data = "{}"',
    );
  }
  
  @override
  Future<bool> clearAllDrafts() async {
    final db = await _databaseHelper.database;
    await db.delete('drafts');
    return true;
  }
  
  // ==================== 导出记录相关操作 ====================
  
  @override
  Future<List<ExportRecord>> getAllExportRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<ExportRecord?> getExportRecordById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return ExportRecord.fromMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<ExportRecord> createExportRecord(ExportRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toMap();
    recordMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('export_records', recordMap);
    return record.copyWith(id: id);
  }
  
  @override
  Future<ExportRecord> updateExportRecord(ExportRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toMap();
    
    await db.update(
      'export_records',
      recordMap,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    
    return record;
  }
  
  @override
  Future<bool> deleteExportRecord(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      'export_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<List<ExportRecord>> getExportRecordsByType(ExportType type, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_type = ?',
      whereArgs: [type.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getExportRecordsByRange(ExportRange range, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_scope = ?',
      whereArgs: [range.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getExportRecordsByStatus(ExportStatus status, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getExportRecordsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_time >= ? AND export_time < ?',
      whereArgs: [startStr, endStr],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getLatestExportRecords({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
      limit: limit,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getSuccessfulExportRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [ExportStatus.success.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getFailedExportRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [ExportStatus.failed.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromMap(map)).toList();
  }
  
  @override
  Future<Map<String, List<ExportRecord>>> getExportRecordsByTypeAndRange() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
    );
    
    final records = maps.map((map) => ExportRecord.fromMap(map)).toList();
    final Map<String, List<ExportRecord>> groupedRecords = {};
    
    for (final record in records) {
      final key = '${record.exportType.name}_${record.exportScope.name}';
      if (!groupedRecords.containsKey(key)) {
        groupedRecords[key] = [];
      }
      groupedRecords[key]!.add(record);
    }
    
    return groupedRecords;
  }
  
  @override
  Future<int> cleanupOldExportRecords(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'export_records',
      where: 'export_time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<int> cleanupFailedExportRecords() async {
    final db = await _databaseHelper.database;
    
    return await db.delete(
      'export_records',
      where: 'status = ?',
      whereArgs: [ExportStatus.failed.name],
    );
  }
  
  @override
  Future<bool> clearAllExportRecords() async {
    final db = await _databaseHelper.database;
    await db.delete('export_records');
    return true;
  }
  
  // ==================== 数据库管理操作 ====================
  
  @override
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    return await _databaseHelper.getDatabaseInfo();
  }
  
  @override
  Future<String> backupDatabase(String backupPath) async {
    return await _databaseHelper.backupDatabase(backupPath);
  }
  
  @override
  Future<bool> restoreDatabase(String backupPath) async {
    return await _databaseHelper.restoreDatabase(backupPath);
  }
  
  @override
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    return await _databaseHelper.validateDataIntegrity();
  }
  
  @override
  Future<Map<String, dynamic>> repairDataIntegrity() async {
    final success = await _databaseHelper.repairDataIntegrity();
    return {
      'success': success,
      'repairedAt': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  Future<bool> clearAllData() async {
    try {
      await _databaseHelper.clearAllData();
      return true;
    } catch (e) {
      return false;
    }
  }
}