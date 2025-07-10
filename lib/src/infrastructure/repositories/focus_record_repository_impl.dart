import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/focus_record.dart';
import '../../domain/repositories/focus_record_repository.dart';

/// 专注记录仓库实现类
/// 实现FocusRecordRepository接口，提供具体的数据库操作逻辑
class FocusRecordRepositoryImpl implements FocusRecordRepository {
  final DatabaseHelper _databaseHelper;
  
  FocusRecordRepositoryImpl(this._databaseHelper);
  
  @override
  Future<List<FocusRecord>> getAllRecords({int? limit, int? offset}) async {
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
  Future<FocusRecord?> getRecordById(int id) async {
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
  Future<FocusRecord> createRecord(FocusRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toMap();
    recordMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('focus_records', recordMap);
    return record.copyWith(id: id);
  }
  
  @override
  Future<FocusRecord> updateRecord(FocusRecord record) async {
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
  Future<bool> deleteRecord(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      'focus_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  @override
  Future<int> deleteRecords(List<int> ids) async {
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
  Future<FocusRecord?> getActiveSession() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'status IN (?, ?)',
      whereArgs: [FocusSessionStatus.active.index, FocusSessionStatus.paused.index],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return FocusRecord.fromMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<List<FocusRecord>> getRecordsByTask(int taskId, {int? limit, int? offset}) async {
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
  Future<List<FocusRecord>> getRecordsByStatus(
    FocusSessionStatus status, 
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getRecordsByModeType(
    FocusModeType modeType, 
    {int? limit, int? offset}
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'mode_type = ?',
      whereArgs: [modeType.index],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getRecordsByDateRange(
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
    
    return maps.map((map) => FocusRecord.fromMap(map)).toList();
  }
  
  @override
  Future<List<FocusRecord>> getTodayRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getRecordsByDateRange(startOfDay, endOfDay, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getThisWeekRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getRecordsByDateRange(startOfWeek, endOfWeek, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getThisMonthRecords({int? limit, int? offset}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return getRecordsByDateRange(startOfMonth, endOfMonth, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getCompletedRecords({int? limit, int? offset}) async {
    return getRecordsByStatus(FocusSessionStatus.completed, limit: limit, offset: offset);
  }
  
  @override
  Future<List<FocusRecord>> getInterruptedRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      where: 'interruption_count > 0',
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FocusRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<FocusStatistics> getFocusStatistics() async {
    final db = await _databaseHelper.database;
    
    // 获取基本统计
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM focus_records');
    final totalSessions = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE status = ?',
      [FocusSessionStatus.completed.index],
    );
    final completedSessions = Sqflite.firstIntValue(completedResult) ?? 0;
    
    final interruptedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE interruption_count > 0',
    );
    final interruptedSessions = Sqflite.firstIntValue(interruptedResult) ?? 0;
    
    final cancelledResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE status = ?',
      [FocusSessionStatus.cancelled.index],
    );
    final cancelledSessions = Sqflite.firstIntValue(cancelledResult) ?? 0;
    
    // 获取时间统计
    final timeResult = await db.rawQuery(
      'SELECT SUM(actual_minutes) as totalActual, SUM(planned_minutes) as totalPlanned, AVG(actual_minutes) as avgActual FROM focus_records',
    );
    final timeMap = timeResult.first;
    final totalFocusMinutes = (timeMap['totalActual'] as num?)?.toInt() ?? 0;
    final totalPlannedMinutes = (timeMap['totalPlanned'] as num?)?.toInt() ?? 0;
    final averageSessionMinutes = (timeMap['avgActual'] as num?)?.toDouble() ?? 0.0;
    
    // 计算完成率和效率
    final completionRate = totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0;
    final averageEfficiency = totalPlannedMinutes > 0 ? (totalFocusMinutes / totalPlannedMinutes) * 100 : 0.0;
    
    // 获取中断统计
    final interruptionResult = await db.rawQuery(
      'SELECT SUM(interruption_count) as totalInterruptions, AVG(interruption_count) as avgInterruptions FROM focus_records',
    );
    final interruptionMap = interruptionResult.first;
    final totalInterruptions = (interruptionMap['totalInterruptions'] as num?)?.toInt() ?? 0;
    final averageInterruptionsPerSession = (interruptionMap['avgInterruptions'] as num?)?.toDouble() ?? 0.0;
    
    // 获取最长和最短会话时间
    final durationResult = await db.rawQuery(
      'SELECT MAX(actual_minutes) as longest, MIN(actual_minutes) as shortest FROM focus_records WHERE actual_minutes > 0',
    );
    final durationMap = durationResult.first;
    final longestSessionMinutes = (durationMap['longest'] as num?)?.toInt() ?? 0;
    final shortestSessionMinutes = (durationMap['shortest'] as num?)?.toInt() ?? 0;
    
    // 获取按模式类型分组的统计
    final sessionsByModeType = <FocusModeType, int>{};
    final minutesByModeType = <FocusModeType, int>{};
    
    for (final modeType in FocusModeType.values) {
      final sessionResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM focus_records WHERE mode_type = ?',
        [modeType.index],
      );
      sessionsByModeType[modeType] = Sqflite.firstIntValue(sessionResult) ?? 0;
      
      final minutesResult = await db.rawQuery(
        'SELECT SUM(actual_minutes) as total FROM focus_records WHERE mode_type = ?',
        [modeType.index],
      );
      minutesByModeType[modeType] = (minutesResult.first['total'] as num?)?.toInt() ?? 0;
    }
    
    // 获取最早和最新会话日期
    final dateResult = await db.rawQuery(
      'SELECT MIN(start_time) as first, MAX(start_time) as last FROM focus_records',
    );
    final dateMap = dateResult.first;
    final firstSessionDate = dateMap['first'] != null 
        ? DateTime.parse(dateMap['first'] as String) 
        : null;
    final lastSessionDate = dateMap['last'] != null 
        ? DateTime.parse(dateMap['last'] as String) 
        : null;
    
    // 计算连续专注天数（简化实现）
    int streakDays = 0;
    if (firstSessionDate != null && lastSessionDate != null) {
      final daysDiff = DateTime.now().difference(lastSessionDate).inDays;
      if (daysDiff <= 1) {
        // 这里可以实现更复杂的连续天数计算逻辑
        streakDays = 1;
      }
    }
    
    return FocusStatistics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      interruptedSessions: interruptedSessions,
      cancelledSessions: cancelledSessions,
      totalFocusMinutes: totalFocusMinutes,
      totalPlannedMinutes: totalPlannedMinutes,
      averageSessionMinutes: averageSessionMinutes,
      completionRate: completionRate,
      averageEfficiency: averageEfficiency,
      averageQualityScore: 0.0, // 这里可以根据实际需求计算质量分数
      totalInterruptions: totalInterruptions,
      averageInterruptionsPerSession: averageInterruptionsPerSession,
      longestSessionMinutes: longestSessionMinutes,
      shortestSessionMinutes: shortestSessionMinutes,
      sessionsByModeType: sessionsByModeType,
      minutesByModeType: minutesByModeType,
      firstSessionDate: firstSessionDate,
      lastSessionDate: lastSessionDate,
      streakDays: streakDays,
    );
  }
  
  @override
  Future<FocusStatistics> getTaskFocusStatistics(int taskId) async {
    final db = await _databaseHelper.database;
    
    // 获取特定任务的基本统计
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE task_id = ?',
      [taskId],
    );
    final totalSessions = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE task_id = ? AND status = ?',
      [taskId, FocusSessionStatus.completed.index],
    );
    final completedSessions = Sqflite.firstIntValue(completedResult) ?? 0;
    
    // 其他统计逻辑类似于getFocusStatistics，但添加taskId过滤条件
    // 为了简化，这里返回基本统计
    return FocusStatistics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      interruptedSessions: 0,
      cancelledSessions: 0,
      totalFocusMinutes: 0,
      totalPlannedMinutes: 0,
      averageSessionMinutes: 0.0,
      completionRate: totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0,
      averageEfficiency: 0.0,
      averageQualityScore: 0.0,
      totalInterruptions: 0,
      averageInterruptionsPerSession: 0.0,
      longestSessionMinutes: 0,
      shortestSessionMinutes: 0,
      sessionsByModeType: {},
      minutesByModeType: {},
      firstSessionDate: null,
      lastSessionDate: null,
      streakDays: 0,
    );
  }
  
  @override
  Future<FocusStatistics> getFocusStatisticsByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    final db = await _databaseHelper.database;
    
    // 获取日期范围内的基本统计
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE start_time >= ? AND start_time < ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final totalSessions = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE start_time >= ? AND start_time < ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), FocusSessionStatus.completed.index],
    );
    final completedSessions = Sqflite.firstIntValue(completedResult) ?? 0;
    
    final interruptedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE start_time >= ? AND start_time < ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), FocusSessionStatus.interrupted.index],
    );
    final interruptedSessions = Sqflite.firstIntValue(interruptedResult) ?? 0;
    
    final cancelledResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_records WHERE start_time >= ? AND start_time < ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), FocusSessionStatus.cancelled.index],
    );
    final cancelledSessions = Sqflite.firstIntValue(cancelledResult) ?? 0;
    
    // 获取专注时长统计
    final focusTimeResult = await db.rawQuery(
      'SELECT SUM(actual_minutes) as total_focus, SUM(planned_minutes) as total_planned FROM focus_records WHERE start_time >= ? AND start_time < ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final totalFocusMinutes = (focusTimeResult.first['total_focus'] as num?)?.toInt() ?? 0;
    final totalPlannedMinutes = (focusTimeResult.first['total_planned'] as num?)?.toInt() ?? 0;
    
    // 计算平均值
    final averageSessionMinutes = totalSessions > 0 ? totalFocusMinutes / totalSessions : 0.0;
    final completionRate = totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0;
    final averageEfficiency = totalPlannedMinutes > 0 ? (totalFocusMinutes / totalPlannedMinutes) * 100 : 0.0;
    
    // 获取中断统计
    final interruptionResult = await db.rawQuery(
      'SELECT SUM(interruption_count) as total_interruptions FROM focus_records WHERE start_time >= ? AND start_time < ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final totalInterruptions = (interruptionResult.first['total_interruptions'] as num?)?.toInt() ?? 0;
    final averageInterruptionsPerSession = totalSessions > 0 ? totalInterruptions / totalSessions : 0.0;
    
    // 获取最长和最短会话
    final sessionLengthResult = await db.rawQuery(
      'SELECT MAX(actual_minutes) as longest, MIN(actual_minutes) as shortest FROM focus_records WHERE start_time >= ? AND start_time < ? AND actual_minutes > 0',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final longestSessionMinutes = (sessionLengthResult.first['longest'] as num?)?.toInt() ?? 0;
    final shortestSessionMinutes = (sessionLengthResult.first['shortest'] as num?)?.toInt() ?? 0;
    
    // 获取按模式类型的统计
    final modeTypeResult = await db.rawQuery(
      'SELECT mode_type, COUNT(*) as sessions, SUM(actual_minutes) as minutes FROM focus_records WHERE start_time >= ? AND start_time < ? GROUP BY mode_type',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    final Map<FocusModeType, int> sessionsByModeType = {};
    final Map<FocusModeType, int> minutesByModeType = {};
    
    for (final row in modeTypeResult) {
      final modeTypeIndex = row['mode_type'] as int;
      final modeType = FocusModeType.values[modeTypeIndex];
      sessionsByModeType[modeType] = (row['sessions'] as num).toInt();
      minutesByModeType[modeType] = (row['minutes'] as num?)?.toInt() ?? 0;
    }
    
    // 获取日期范围
    final dateRangeResult = await db.rawQuery(
      'SELECT MIN(start_time) as first_date, MAX(start_time) as last_date FROM focus_records WHERE start_time >= ? AND start_time < ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    DateTime? firstSessionDate;
    DateTime? lastSessionDate;
    
    if (dateRangeResult.isNotEmpty) {
      final firstDateStr = dateRangeResult.first['first_date'] as String?;
      final lastDateStr = dateRangeResult.first['last_date'] as String?;
      
      if (firstDateStr != null) {
        firstSessionDate = DateTime.parse(firstDateStr);
      }
      if (lastDateStr != null) {
        lastSessionDate = DateTime.parse(lastDateStr);
      }
    }
    
    return FocusStatistics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      interruptedSessions: interruptedSessions,
      cancelledSessions: cancelledSessions,
      totalFocusMinutes: totalFocusMinutes,
      totalPlannedMinutes: totalPlannedMinutes,
      averageSessionMinutes: averageSessionMinutes,
      completionRate: completionRate,
      averageEfficiency: averageEfficiency,
      averageQualityScore: 0.0,
      totalInterruptions: totalInterruptions,
      averageInterruptionsPerSession: averageInterruptionsPerSession,
      longestSessionMinutes: longestSessionMinutes,
      shortestSessionMinutes: shortestSessionMinutes,
      sessionsByModeType: sessionsByModeType,
      minutesByModeType: minutesByModeType,
      firstSessionDate: firstSessionDate,
      lastSessionDate: lastSessionDate,
      streakDays: 0, // 连续天数计算较复杂，暂时设为0
    );
  }
  
  @override
  Future<List<DailyFocusStats>> getDailyFocusStats(int days) async {
    final db = await _databaseHelper.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final List<DailyFocusStats> dailyStats = [];
    
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as sessions, SUM(actual_minutes) as minutes FROM focus_records WHERE start_time >= ? AND start_time < ?',
        [dayStart.toIso8601String(), dayEnd.toIso8601String()],
      );
      
      final map = result.first;
      dailyStats.add(DailyFocusStats(
        date: dayStart,
        totalSessions: (map['sessions'] as num?)?.toInt() ?? 0,
        totalMinutes: (map['minutes'] as num?)?.toInt() ?? 0,
        completedSessions: 0, // 可以进一步查询
        averageQualityScore: 0.0,
      ));
    }
    
    return dailyStats;
  }
  
  @override
  Future<List<WeeklyFocusStats>> getWeeklyFocusStats(int weeks) async {
    // 实现周统计逻辑
    return [];
  }
  
  @override
  Future<List<MonthlyFocusStats>> getMonthlyFocusStats(int months) async {
    // 实现月统计逻辑
    return [];
  }
  
  @override
  Future<List<FocusRecord>> getFocusLeaderboard({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_records',
      orderBy: 'actual_minutes DESC',
      limit: limit,
    );
    
    return maps.map((map) => FocusRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<String> exportRecords(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  ) async {
    List<FocusRecord> records;
    
    if (startDate != null && endDate != null) {
      records = await getRecordsByDateRange(startDate, endDate);
    } else {
      records = await getAllRecords();
    }
    
    if (format.toLowerCase() == 'json') {
      final recordsJson = records.map((record) => record.toJson()).toList();
      return recordsJson.toString();
    } else if (format.toLowerCase() == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('ID,TaskID,TaskTitle,ModeType,PlannedMinutes,ActualMinutes,Status,StartTime,EndTime,InterruptionCount,Notes');
      
      for (final record in records) {
        buffer.writeln([
          record.id,
          record.taskId,
          '"${record.taskTitle?.replaceAll('"', '""') ?? ''}"',
          record.modeType.name,
          record.plannedMinutes,
          record.actualMinutes,
          record.status.name,
          record.startTime.toIso8601String(),
          record.endTime?.toIso8601String() ?? '',
          record.interruptionCount,
          '"${record.notes?.replaceAll('"', '""') ?? ''}"',
        ].join(','));
      }
      
      return buffer.toString();
    }
    
    throw UnsupportedError('Unsupported export format: $format');
  }
  
  @override
  Future<int> importRecords(String data, String format) async {
    // 这里可以实现导入逻辑
    // 由于复杂性，暂时返回0
    return 0;
  }
  
  @override
  Future<bool> clearAllRecords() async {
    final db = await _databaseHelper.database;
    await db.delete('focus_records');
    return true;
  }
  
  @override
  Future<int> cleanupOldRecords(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'focus_records',
      where: 'start_time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    return await _databaseHelper.getDatabaseInfo();
  }
}