import '../entities/export_record.dart';

/// 导出记录仓库接口
/// 定义导出记录数据操作的抽象方法，遵循Clean Architecture的依赖倒置原则
abstract class ExportRecordRepository {
  /// 获取所有导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getAllRecords({int? limit, int? offset});
  
  /// 根据ID获取导出记录
  /// [id] 记录ID
  /// 返回导出记录实例，如果不存在则返回null
  Future<ExportRecord?> getRecordById(int id);
  
  /// 创建新的导出记录
  /// [record] 要创建的导出记录实例
  /// 返回创建后的记录（包含生成的ID）
  Future<ExportRecord> createRecord(ExportRecord record);
  
  /// 更新导出记录
  /// [record] 要更新的导出记录实例
  /// 返回更新后的记录
  Future<ExportRecord> updateRecord(ExportRecord record);
  
  /// 删除导出记录
  /// [id] 要删除的记录ID
  /// 返回是否删除成功
  Future<bool> deleteRecord(int id);
  
  /// 批量删除导出记录
  /// [ids] 要删除的记录ID列表
  /// 返回成功删除的记录数量
  Future<int> deleteRecords(List<int> ids);
  
  /// 按导出类型筛选记录
  /// [type] 导出类型
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getRecordsByType(
    ExportType type, 
    {int? limit, int? offset}
  );
  
  /// 按导出范围筛选记录
  /// [scope] 导出范围
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getRecordsByScope(
    ExportScope scope, 
    {int? limit, int? offset}
  );
  
  /// 按状态筛选记录
  /// [status] 导出状态
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getRecordsByStatus(
    ExportStatus status, 
    {int? limit, int? offset}
  );
  
  /// 获取成功的导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getSuccessfulRecords({int? limit, int? offset});
  
  /// 获取失败的导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getFailedRecords({int? limit, int? offset});
  
  /// 获取最新的导出记录
  /// [limit] 限制返回的记录数量
  Future<List<ExportRecord>> getLatestRecords({int limit = 10});
  
  /// 获取指定日期范围内的导出记录
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getRecordsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  );
  
  /// 获取今天的导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getTodayRecords({int? limit, int? offset});
  
  /// 获取本周的导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getThisWeekRecords({int? limit, int? offset});
  
  /// 获取本月的导出记录
  /// [limit] 限制返回的记录数量
  /// [offset] 偏移量，用于分页
  Future<List<ExportRecord>> getThisMonthRecords({int? limit, int? offset});
  
  /// 按导出类型和范围分组获取记录
  /// 返回按类型和范围分组的导出记录映射
  Future<Map<String, List<ExportRecord>>> getRecordsGroupedByTypeAndScope();
  
  /// 清理过期的导出记录
  /// [daysToKeep] 保留最近多少天的记录
  /// 返回清理的记录数量
  Future<int> cleanupOldRecords(int daysToKeep);
  
  /// 清理失败的导出记录
  /// [daysToKeep] 保留最近多少天的失败记录
  /// 返回清理的记录数量
  Future<int> cleanupFailedRecords(int daysToKeep);
  
  /// 获取导出记录统计信息
  Future<ExportStatistics> getExportStatistics();
  
  /// 获取指定日期范围内的导出统计信息
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<ExportStatistics> getExportStatisticsByDateRange(
    DateTime startDate, 
    DateTime endDate
  );
  
  /// 导出导出记录数据
  /// [format] 导出格式（如 'json', 'csv'）
  /// [startDate] 开始日期（可选）
  /// [endDate] 结束日期（可选）
  Future<String> exportRecords(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// 清空所有导出记录数据
  Future<bool> clearAllRecords();
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo();
}

/// 导出统计信息
class ExportStatistics {
  final int totalExports;
  final int successfulExports;
  final int failedExports;
  final double successRate;
  final int todayExports;
  final int thisWeekExports;
  final int thisMonthExports;
  final Map<ExportType, int> exportsByType;
  final Map<ExportScope, int> exportsByScope;
  final Map<ExportStatus, int> exportsByStatus;
  final DateTime? firstExportDate;
  final DateTime? lastExportDate;
  final double averageExportsPerDay;
  final List<String> commonErrorMessages;
  
  const ExportStatistics({
    required this.totalExports,
    required this.successfulExports,
    required this.failedExports,
    required this.successRate,
    required this.todayExports,
    required this.thisWeekExports,
    required this.thisMonthExports,
    required this.exportsByType,
    required this.exportsByScope,
    required this.exportsByStatus,
    this.firstExportDate,
    this.lastExportDate,
    required this.averageExportsPerDay,
    required this.commonErrorMessages,
  });
  
  /// 从Map创建ExportStatistics实例
  factory ExportStatistics.fromMap(Map<String, dynamic> map) {
    return ExportStatistics(
      totalExports: map['totalExports'] as int,
      successfulExports: map['successfulExports'] as int,
      failedExports: map['failedExports'] as int,
      successRate: (map['successRate'] as num).toDouble(),
      todayExports: map['todayExports'] as int,
      thisWeekExports: map['thisWeekExports'] as int,
      thisMonthExports: map['thisMonthExports'] as int,
      exportsByType: Map<ExportType, int>.from(
        (map['exportsByType'] as Map).map(
          (key, value) => MapEntry(
            ExportType.values.firstWhere((e) => e.toString() == key),
            value as int,
          ),
        ),
      ),
      exportsByScope: Map<ExportScope, int>.from(
        (map['exportsByScope'] as Map).map(
          (key, value) => MapEntry(
            ExportScope.values.firstWhere((e) => e.toString() == key),
            value as int,
          ),
        ),
      ),
      exportsByStatus: Map<ExportStatus, int>.from(
        (map['exportsByStatus'] as Map).map(
          (key, value) => MapEntry(
            ExportStatus.values.firstWhere((e) => e.toString() == key),
            value as int,
          ),
        ),
      ),
      firstExportDate: map['firstExportDate'] != null 
          ? DateTime.parse(map['firstExportDate'] as String) 
          : null,
      lastExportDate: map['lastExportDate'] != null 
          ? DateTime.parse(map['lastExportDate'] as String) 
          : null,
      averageExportsPerDay: (map['averageExportsPerDay'] as num).toDouble(),
      commonErrorMessages: List<String>.from(map['commonErrorMessages'] as List),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalExports': totalExports,
      'successfulExports': successfulExports,
      'failedExports': failedExports,
      'successRate': successRate,
      'todayExports': todayExports,
      'thisWeekExports': thisWeekExports,
      'thisMonthExports': thisMonthExports,
      'exportsByType': exportsByType.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'exportsByScope': exportsByScope.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'exportsByStatus': exportsByStatus.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'firstExportDate': firstExportDate?.toIso8601String(),
      'lastExportDate': lastExportDate?.toIso8601String(),
      'averageExportsPerDay': averageExportsPerDay,
      'commonErrorMessages': commonErrorMessages,
    };
  }
  
  /// 转换为JSON字符串
  String toJson() {
    return toMap().toString();
  }
}