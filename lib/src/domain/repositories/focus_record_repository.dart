import '../entities/focus_record.dart';

/// 专注记录仓库接口
/// 定义专注记录数据操作的抽象方法，遵循Clean Architecture的依赖倒置原则
abstract class FocusRecordRepository {
  /// 获取所有专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getAllRecords({int? limit, int? offset});
  
  /// 根据ID获取专注记录
  /// [id] 记录ID
  /// 返回专注记录实例，如果不存在则返回null
  Future<FocusRecord?> getRecordById(int id);
  
  /// 创建新的专注记录
  /// [record] 要创建的专注记录实例
  /// 返回创建后的记录（包含生成的ID）
  Future<FocusRecord> createRecord(FocusRecord record);
  
  /// 更新专注记录
  /// [record] 要更新的专注记录实例
  /// 返回更新后的记录
  Future<FocusRecord> updateRecord(FocusRecord record);
  
  /// 删除专注记录
  /// [id] 要删除的记录ID
  /// 返回是否删除成功
  Future<bool> deleteRecord(int id);
  
  /// 批量删除专注记录
  /// [ids] 要删除的记录ID列表
  /// 返回成功删除的记录数量
  Future<int> deleteRecords(List<int> ids);
  
  /// 获取当前活跃的专注会话
  /// 返回正在进行中或暂停的专注记录
  Future<FocusRecord?> getActiveSession();
  
  /// 获取特定任务的专注记录
  /// [taskId] 任务ID
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getRecordsByTask(int taskId, {int? limit, int? offset});
  
  /// 按状态筛选专注记录
  /// [status] 专注会话状态
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getRecordsByStatus(
    FocusSessionStatus status, 
    {int? limit, int? offset}
  );
  
  /// 按模式类型筛选专注记录
  /// [modeType] 专注模式类型
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getRecordsByModeType(
    FocusModeType modeType, 
    {int? limit, int? offset}
  );
  
  /// 获取指定日期范围内的专注记录
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getRecordsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  );
  
  /// 获取今天的专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getTodayRecords({int? limit, int? offset});
  
  /// 获取本周的专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getThisWeekRecords({int? limit, int? offset});
  
  /// 获取本月的专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getThisMonthRecords({int? limit, int? offset});
  
  /// 获取已完成的专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getCompletedRecords({int? limit, int? offset});
  
  /// 获取被中断的专注记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<FocusRecord>> getInterruptedRecords({int? limit, int? offset});
  
  /// 获取专注记录统计信息
  Future<FocusStatistics> getFocusStatistics();
  
  /// 获取特定任务的专注统计信息
  /// [taskId] 任务ID
  Future<FocusStatistics> getTaskFocusStatistics(int taskId);
  
  /// 获取指定日期范围内的专注统计信息
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<FocusStatistics> getFocusStatisticsByDateRange(
    DateTime startDate, 
    DateTime endDate
  );
  
  /// 获取每日专注统计数据
  /// [days] 获取最近多少天的数据
  Future<List<DailyFocusStats>> getDailyFocusStats(int days);
  
  /// 获取每周专注统计数据
  /// [weeks] 获取最近多少周的数据
  Future<List<WeeklyFocusStats>> getWeeklyFocusStats(int weeks);
  
  /// 获取每月专注统计数据
  /// [months] 获取最近多少月的数据
  Future<List<MonthlyFocusStats>> getMonthlyFocusStats(int months);
  
  /// 获取专注时长排行榜
  /// [limit] 限制返回的记录数量
  Future<List<FocusRecord>> getFocusLeaderboard({int limit = 10});
  
  /// 导出专注记录数据
  /// [format] 导出格式（如 'json', 'csv'）
  /// [startDate] 开始日期（可选）
  /// [endDate] 结束日期（可选）
  Future<String> exportRecords(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// 导入专注记录数据
  /// [data] 要导入的数据
  /// [format] 数据格式
  /// 返回成功导入的记录数量
  Future<int> importRecords(String data, String format);
  
  /// 清空所有专注记录数据
  Future<bool> clearAllRecords();
  
  /// 清理过期的专注记录
  /// [daysToKeep] 保留最近多少天的记录
  /// 返回清理的记录数量
  Future<int> cleanupOldRecords(int daysToKeep);
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo();
}

/// 专注统计信息
class FocusStatistics {
  final int totalSessions;
  final int completedSessions;
  final int interruptedSessions;
  final int cancelledSessions;
  final int totalFocusMinutes;
  final int totalPlannedMinutes;
  final double averageSessionMinutes;
  final double completionRate;
  final double averageEfficiency;
  final double averageQualityScore;
  final int totalInterruptions;
  final double averageInterruptionsPerSession;
  final int longestSessionMinutes;
  final int shortestSessionMinutes;
  final Map<FocusModeType, int> sessionsByModeType;
  final Map<FocusModeType, int> minutesByModeType;
  final DateTime? firstSessionDate;
  final DateTime? lastSessionDate;
  final int streakDays; // 连续专注天数
  
  const FocusStatistics({
    required this.totalSessions,
    required this.completedSessions,
    required this.interruptedSessions,
    required this.cancelledSessions,
    required this.totalFocusMinutes,
    required this.totalPlannedMinutes,
    required this.averageSessionMinutes,
    required this.completionRate,
    required this.averageEfficiency,
    required this.averageQualityScore,
    required this.totalInterruptions,
    required this.averageInterruptionsPerSession,
    required this.longestSessionMinutes,
    required this.shortestSessionMinutes,
    required this.sessionsByModeType,
    required this.minutesByModeType,
    this.firstSessionDate,
    this.lastSessionDate,
    required this.streakDays,
  });
  
  /// 从Map创建FocusStatistics实例
  factory FocusStatistics.fromMap(Map<String, dynamic> map) {
    return FocusStatistics(
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int,
      interruptedSessions: map['interruptedSessions'] as int,
      cancelledSessions: map['cancelledSessions'] as int,
      totalFocusMinutes: map['totalFocusMinutes'] as int,
      totalPlannedMinutes: map['totalPlannedMinutes'] as int,
      averageSessionMinutes: map['averageSessionMinutes'] as double,
      completionRate: map['completionRate'] as double,
      averageEfficiency: map['averageEfficiency'] as double,
      averageQualityScore: map['averageQualityScore'] as double,
      totalInterruptions: map['totalInterruptions'] as int,
      averageInterruptionsPerSession: map['averageInterruptionsPerSession'] as double,
      longestSessionMinutes: map['longestSessionMinutes'] as int,
      shortestSessionMinutes: map['shortestSessionMinutes'] as int,
      sessionsByModeType: Map<FocusModeType, int>.from(
        (map['sessionsByModeType'] as Map).map(
          (key, value) => MapEntry(FocusModeType.values[key as int], value as int),
        ),
      ),
      minutesByModeType: Map<FocusModeType, int>.from(
        (map['minutesByModeType'] as Map).map(
          (key, value) => MapEntry(FocusModeType.values[key as int], value as int),
        ),
      ),
      firstSessionDate: map['firstSessionDate'] != null 
          ? DateTime.parse(map['firstSessionDate'] as String)
          : null,
      lastSessionDate: map['lastSessionDate'] != null 
          ? DateTime.parse(map['lastSessionDate'] as String)
          : null,
      streakDays: map['streakDays'] as int,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'interruptedSessions': interruptedSessions,
      'cancelledSessions': cancelledSessions,
      'totalFocusMinutes': totalFocusMinutes,
      'totalPlannedMinutes': totalPlannedMinutes,
      'averageSessionMinutes': averageSessionMinutes,
      'completionRate': completionRate,
      'averageEfficiency': averageEfficiency,
      'averageQualityScore': averageQualityScore,
      'totalInterruptions': totalInterruptions,
      'averageInterruptionsPerSession': averageInterruptionsPerSession,
      'longestSessionMinutes': longestSessionMinutes,
      'shortestSessionMinutes': shortestSessionMinutes,
      'sessionsByModeType': sessionsByModeType.map(
        (key, value) => MapEntry(key.index, value),
      ),
      'minutesByModeType': minutesByModeType.map(
        (key, value) => MapEntry(key.index, value),
      ),
      'firstSessionDate': firstSessionDate?.toIso8601String(),
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'streakDays': streakDays,
    };
  }
  
  @override
  String toString() {
    return 'FocusStatistics(totalSessions: $totalSessions, totalFocusMinutes: $totalFocusMinutes, completionRate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 每日专注统计
class DailyFocusStats {
  final DateTime date;
  final int totalSessions;
  final int completedSessions;
  final int totalMinutes;
  final double averageQualityScore;
  
  const DailyFocusStats({
    required this.date,
    required this.totalSessions,
    required this.completedSessions,
    required this.totalMinutes,
    required this.averageQualityScore,
  });
  
  factory DailyFocusStats.fromMap(Map<String, dynamic> map) {
    return DailyFocusStats(
      date: DateTime.parse(map['date'] as String),
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int,
      totalMinutes: map['totalMinutes'] as int,
      averageQualityScore: map['averageQualityScore'] as double,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'totalMinutes': totalMinutes,
      'averageQualityScore': averageQualityScore,
    };
  }
}

/// 每周专注统计
class WeeklyFocusStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalSessions;
  final int completedSessions;
  final int totalMinutes;
  final double averageQualityScore;
  final int activeDays; // 本周有专注活动的天数
  
  const WeeklyFocusStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSessions,
    required this.completedSessions,
    required this.totalMinutes,
    required this.averageQualityScore,
    required this.activeDays,
  });
  
  factory WeeklyFocusStats.fromMap(Map<String, dynamic> map) {
    return WeeklyFocusStats(
      weekStart: DateTime.parse(map['weekStart'] as String),
      weekEnd: DateTime.parse(map['weekEnd'] as String),
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int,
      totalMinutes: map['totalMinutes'] as int,
      averageQualityScore: map['averageQualityScore'] as double,
      activeDays: map['activeDays'] as int,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'totalMinutes': totalMinutes,
      'averageQualityScore': averageQualityScore,
      'activeDays': activeDays,
    };
  }
}

/// 每月专注统计
class MonthlyFocusStats {
  final int year;
  final int month;
  final int totalSessions;
  final int completedSessions;
  final int totalMinutes;
  final double averageQualityScore;
  final int activeDays; // 本月有专注活动的天数
  
  const MonthlyFocusStats({
    required this.year,
    required this.month,
    required this.totalSessions,
    required this.completedSessions,
    required this.totalMinutes,
    required this.averageQualityScore,
    required this.activeDays,
  });
  
  factory MonthlyFocusStats.fromMap(Map<String, dynamic> map) {
    return MonthlyFocusStats(
      year: map['year'] as int,
      month: map['month'] as int,
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int,
      totalMinutes: map['totalMinutes'] as int,
      averageQualityScore: map['averageQualityScore'] as double,
      activeDays: map['activeDays'] as int,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'totalMinutes': totalMinutes,
      'averageQualityScore': averageQualityScore,
      'activeDays': activeDays,
    };
  }
  
  DateTime get monthStart => DateTime(year, month, 1);
  DateTime get monthEnd => DateTime(year, month + 1, 0);
}