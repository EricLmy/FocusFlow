import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/draft.dart';
import '../../domain/repositories/draft_repository.dart';

/// 草稿仓库实现类
/// 实现DraftRepository接口，提供具体的数据库操作逻辑
class DraftRepositoryImpl implements DraftRepository {
  final DatabaseHelper _databaseHelper;
  
  DraftRepositoryImpl(this._databaseHelper);
  
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
  Future<String> exportDrafts(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  ) async {
    List<Draft> drafts;
    
    if (startDate != null && endDate != null) {
      drafts = await getDraftsByDateRange(startDate, endDate);
    } else {
      drafts = await getAllDrafts();
    }
    
    if (format.toLowerCase() == 'json') {
      final draftsJson = drafts.map((draft) => draft.toJson()).toList();
      return draftsJson.toString();
    } else if (format.toLowerCase() == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('ID,TaskData,SaveTime');
      
      for (final draft in drafts) {
        buffer.writeln([
          draft.id,
          '"${draft.taskData.toString().replaceAll('"', '""')}"',
          draft.saveTime.toIso8601String(),
        ].join(','));
      }
      
      return buffer.toString();
    }
    
    throw UnsupportedError('Unsupported export format: $format');
  }
  
  @override
  Future<int> importDrafts(String data, String format) async {
    // 这里可以实现导入逻辑
    // 由于复杂性，暂时返回0
    return 0;
  }
  
  @override
  Future<bool> clearAllDrafts() async {
    final db = await _databaseHelper.database;
    await db.delete('drafts');
    return true;
  }
  
  @override
  Future<DraftStatistics> getDraftStatistics() async {
    final db = await _databaseHelper.database;
    
    // 获取基本统计
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM drafts');
    final totalDrafts = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final validResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM drafts WHERE task_data IS NOT NULL AND task_data != "" AND task_data != "{}"',
    );
    final validDrafts = Sqflite.firstIntValue(validResult) ?? 0;
    
    final emptyResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM drafts WHERE task_data IS NULL OR task_data = "" OR task_data = "{}"',
    );
    final emptyDrafts = Sqflite.firstIntValue(emptyResult) ?? 0;
    
    // 获取今天的草稿数量
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM drafts WHERE save_time >= ? AND save_time < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final todayDrafts = Sqflite.firstIntValue(todayResult) ?? 0;
    
    // 获取本周的草稿数量
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    final thisWeekResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM drafts WHERE save_time >= ? AND save_time < ?',
      [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()],
    );
    final thisWeekDrafts = Sqflite.firstIntValue(thisWeekResult) ?? 0;
    
    // 获取本月的草稿数量
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    final thisMonthResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM drafts WHERE save_time >= ? AND save_time < ?',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
    final thisMonthDrafts = Sqflite.firstIntValue(thisMonthResult) ?? 0;
    
    // 获取最早和最新草稿日期
    final dateResult = await db.rawQuery(
      'SELECT MIN(save_time) as oldest, MAX(save_time) as newest FROM drafts',
    );
    final dateMap = dateResult.first;
    final oldestDraftDate = dateMap['oldest'] != null 
        ? DateTime.parse(dateMap['oldest'] as String) 
        : null;
    final newestDraftDate = dateMap['newest'] != null 
        ? DateTime.parse(dateMap['newest'] as String) 
        : null;
    
    // 计算平均每日草稿数量
    double averageDraftsPerDay = 0.0;
    if (oldestDraftDate != null && newestDraftDate != null) {
      final daysDiff = newestDraftDate.difference(oldestDraftDate).inDays + 1;
      if (daysDiff > 0) {
        averageDraftsPerDay = totalDrafts / daysDiff;
      }
    }
    
    // 按分类分组统计（简化实现）
    final draftsByCategory = <String, int>{
      'valid': validDrafts,
      'empty': emptyDrafts,
    };
    
    return DraftStatistics(
      totalDrafts: totalDrafts,
      validDrafts: validDrafts,
      emptyDrafts: emptyDrafts,
      todayDrafts: todayDrafts,
      thisWeekDrafts: thisWeekDrafts,
      thisMonthDrafts: thisMonthDrafts,
      oldestDraftDate: oldestDraftDate,
      newestDraftDate: newestDraftDate,
      averageDraftsPerDay: averageDraftsPerDay,
      draftsByCategory: draftsByCategory,
    );
  }
  
  @override
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    return await _databaseHelper.getDatabaseInfo();
  }
}