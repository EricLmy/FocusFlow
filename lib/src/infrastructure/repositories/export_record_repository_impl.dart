import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/export_record.dart';
import '../../domain/repositories/export_record_repository.dart';

/// 导出记录仓库实现类
/// 实现ExportRecordRepository接口，提供具体的数据库操作逻辑
class ExportRecordRepositoryImpl implements ExportRecordRepository {
  final DatabaseHelper _databaseHelper;
  
  ExportRecordRepositoryImpl(this._databaseHelper);
  
  @override
  Future<List<ExportRecord>> getAllRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<ExportRecord?> getRecordById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return ExportRecord.fromDatabaseMap(maps.first);
    }
    return null;
  }
  
  @override
  Future<ExportRecord> createRecord(ExportRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toDatabaseMap();
    recordMap.remove('id'); // 移除ID，让数据库自动生成
    
    final id = await db.insert('export_records', recordMap);
    return record.copyWith(id: id);
  }
  
  @override
  Future<ExportRecord> updateRecord(ExportRecord record) async {
    final db = await _databaseHelper.database;
    final recordMap = record.toDatabaseMap();
    
    await db.update(
      'export_records',
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
      'export_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<int> deleteRecords(List<int> ids) async {
    final db = await _databaseHelper.database;
    int deletedCount = 0;
    for (final id in ids) {
      final count = await db.delete(
        'export_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      deletedCount += count;
    }
    return deletedCount;
  }

  @override
  Future<List<ExportRecord>> getRecordsByType(ExportType type, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_type = ?',
      whereArgs: [type.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getRecordsByScope(ExportScope scope, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_scope = ?',
      whereArgs: [scope.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getRecordsByStatus(ExportStatus status, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getRecordsByDateRange(
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
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getLatestRecords({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
      limit: limit,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getSuccessfulRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [ExportStatus.success.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }
  
  @override
  Future<List<ExportRecord>> getFailedRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'status = ?',
      whereArgs: [ExportStatus.failed.name],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }

  @override
  Future<List<ExportRecord>> getTodayRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_time >= ? AND export_time < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }

  @override
  Future<List<ExportRecord>> getThisWeekRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_time >= ? AND export_time < ?',
      whereArgs: [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }

  @override
  Future<List<ExportRecord>> getThisMonthRecords({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      where: 'export_time >= ? AND export_time < ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'export_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
  }

  @override
  Future<Map<String, List<ExportRecord>>> getRecordsGroupedByTypeAndScope() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'export_records',
      orderBy: 'export_time DESC',
    );
    
    final records = maps.map((map) => ExportRecord.fromDatabaseMap(map)).toList();
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
  Future<int> cleanupOldRecords(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'export_records',
      where: 'export_time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<int> cleanupFailedRecords(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'export_records',
      where: 'status = ? AND export_time < ?',
      whereArgs: [ExportStatus.failed.name, cutoffDate.toIso8601String()],
    );
  }
  
  @override
  Future<ExportStatistics> getExportStatistics() async {
    final db = await _databaseHelper.database;
    
    // 获取基本统计
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM export_records');
    final totalExports = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final successResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE status = ?',
      [ExportStatus.success.name],
    );
    final successfulExports = Sqflite.firstIntValue(successResult) ?? 0;
    
    final failedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE status = ?',
      [ExportStatus.failed.name],
    );
    final failedExports = Sqflite.firstIntValue(failedResult) ?? 0;
    

    
    // 计算成功率
    final successRate = totalExports > 0 ? (successfulExports / totalExports) * 100 : 0.0;
    
    // 获取今天的导出数量
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE export_time >= ? AND export_time < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final todayExports = Sqflite.firstIntValue(todayResult) ?? 0;
    
    // 获取本周的导出数量
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    final thisWeekResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE export_time >= ? AND export_time < ?',
      [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()],
    );
    final thisWeekExports = Sqflite.firstIntValue(thisWeekResult) ?? 0;
    
    // 获取本月的导出数量
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    final thisMonthResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE export_time >= ? AND export_time < ?',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
    final thisMonthExports = Sqflite.firstIntValue(thisMonthResult) ?? 0;
    

    
    // 获取最早和最新导出日期
    final dateResult = await db.rawQuery(
      'SELECT MIN(export_time) as oldest, MAX(export_time) as newest FROM export_records',
    );
    final dateMap = dateResult.first;
    final oldestExportDate = dateMap['oldest'] != null 
        ? DateTime.parse(dateMap['oldest'] as String) 
        : null;
    final newestExportDate = dateMap['newest'] != null 
        ? DateTime.parse(dateMap['newest'] as String) 
        : null;
    
    // 计算平均每日导出数量
    double averageExportsPerDay = 0.0;
    if (oldestExportDate != null && newestExportDate != null) {
      final daysDiff = newestExportDate.difference(oldestExportDate).inDays + 1;
      if (daysDiff > 0) {
        averageExportsPerDay = totalExports / daysDiff;
      }
    }
    
    return ExportStatistics(
      totalExports: totalExports,
      successfulExports: successfulExports,
      failedExports: failedExports,
      successRate: successRate,
      todayExports: todayExports,
      thisWeekExports: thisWeekExports,
      thisMonthExports: thisMonthExports,
      exportsByType: {},
      exportsByScope: {},
      exportsByStatus: {},
      firstExportDate: oldestExportDate,
      lastExportDate: newestExportDate,
      averageExportsPerDay: averageExportsPerDay,
      commonErrorMessages: [],
    );
  }
  
  @override
  Future<String> exportRecords(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  ) async {
    List<ExportRecord> records;
    
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
      buffer.writeln('ID,ExportType,ExportRange,ExportTime,FilePath,Status,ErrorMessage');
      
      for (final record in records) {
        buffer.writeln([
          record.id,
          record.exportType.name,
          record.exportScope.name,
          record.exportTime.toIso8601String(),
          '"${record.filePath.replaceAll('"', '""')}"',
          record.status.name,
          '"${record.errorMsg?.replaceAll('"', '""') ?? ''}"',
        ].join(','));
      }
      
      return buffer.toString();
    }
    
    throw UnsupportedError('Unsupported export format: $format');
  }
  
  @override
  Future<bool> clearAllRecords() async {
    final db = await _databaseHelper.database;
    await db.delete('export_records');
    return true;
  }

  @override
  Future<ExportStatistics> getExportStatisticsByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    final db = await _databaseHelper.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    // 获取基本统计
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE export_time >= ? AND export_time < ?',
      [startStr, endStr],
    );
    final totalExports = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final successResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE status = ? AND export_time >= ? AND export_time < ?',
      [ExportStatus.success.name, startStr, endStr],
    );
    final successfulExports = Sqflite.firstIntValue(successResult) ?? 0;
    
    final failedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM export_records WHERE status = ? AND export_time >= ? AND export_time < ?',
      [ExportStatus.failed.name, startStr, endStr],
    );
    final failedExports = Sqflite.firstIntValue(failedResult) ?? 0;
    
    // 计算成功率
    final successRate = totalExports > 0 ? (successfulExports / totalExports) * 100 : 0.0;
    
    // 计算平均每日导出数量
    final daysDiff = endDate.difference(startDate).inDays + 1;
    final averageExportsPerDay = daysDiff > 0 ? totalExports / daysDiff : 0.0;
    
    return ExportStatistics(
      totalExports: totalExports,
      successfulExports: successfulExports,
      failedExports: failedExports,
      successRate: successRate,
      todayExports: 0,
      thisWeekExports: 0,
      thisMonthExports: 0,
      exportsByType: {},
      exportsByScope: {},
      exportsByStatus: {},
      firstExportDate: startDate,
      lastExportDate: endDate,
      averageExportsPerDay: averageExportsPerDay,
      commonErrorMessages: [],
    );
  }

  @override
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await _databaseHelper.database;
    final totalRecords = await db.rawQuery('SELECT COUNT(*) as count FROM export_records');
    final totalCount = Sqflite.firstIntValue(totalRecords) ?? 0;
    
    return {
      'tableName': 'export_records',
      'totalRecords': totalCount,
      'databasePath': db.path,
      'version': await db.getVersion(),
    };
  }
}