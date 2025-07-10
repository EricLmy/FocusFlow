import '../entities/draft.dart';

/// 草稿仓库接口
/// 定义草稿数据操作的抽象方法，遵循Clean Architecture的依赖倒置原则
abstract class DraftRepository {
  /// 获取所有草稿
  /// [limit] 限制返回的草稿数量
  /// [offset] 偏移量，用于分页
  Future<List<Draft>> getAllDrafts({int? limit, int? offset});
  
  /// 根据ID获取草稿
  /// [id] 草稿ID
  /// 返回草稿实例，如果不存在则返回null
  Future<Draft?> getDraftById(int id);
  
  /// 创建新草稿
  /// [draft] 要创建的草稿实例
  /// 返回创建后的草稿（包含生成的ID）
  Future<Draft> createDraft(Draft draft);
  
  /// 更新草稿
  /// [draft] 要更新的草稿实例
  /// 返回更新后的草稿
  Future<Draft> updateDraft(Draft draft);
  
  /// 删除草稿
  /// [id] 要删除的草稿ID
  /// 返回是否删除成功
  Future<bool> deleteDraft(int id);
  
  /// 批量删除草稿
  /// [ids] 要删除的草稿ID列表
  /// 返回成功删除的草稿数量
  Future<int> deleteDrafts(List<int> ids);
  
  /// 获取最新的草稿
  /// [limit] 限制返回的草稿数量
  Future<List<Draft>> getLatestDrafts({int limit = 10});
  
  /// 搜索草稿
  /// [query] 搜索关键词（在任务标题和描述中搜索）
  /// [limit] 限制返回的草稿数量
  /// [offset] 偏移量，用于分页
  Future<List<Draft>> searchDrafts(String query, {int? limit, int? offset});
  
  /// 获取指定日期范围内的草稿
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  /// [limit] 限制返回的草稿数量
  /// [offset] 偏移量，用于分页
  Future<List<Draft>> getDraftsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  );
  
  /// 获取今天的草稿
  /// [limit] 限制返回的草稿数量
  /// [offset] 偏移量，用于分页
  Future<List<Draft>> getTodayDrafts({int? limit, int? offset});
  
  /// 获取本周的草稿
  /// [limit] 限制返回的草稿数量
  /// [offset] 偏移量，用于分页
  Future<List<Draft>> getThisWeekDrafts({int? limit, int? offset});
  
  /// 清理过期的草稿
  /// [daysToKeep] 保留最近多少天的草稿
  /// 返回清理的草稿数量
  Future<int> cleanupOldDrafts(int daysToKeep);
  
  /// 获取空草稿（无效数据）
  /// 返回包含空或无效任务数据的草稿列表
  Future<List<Draft>> getEmptyDrafts();
  
  /// 清理空草稿
  /// 删除所有包含空或无效任务数据的草稿
  /// 返回清理的草稿数量
  Future<int> cleanupEmptyDrafts();
  
  /// 导出草稿数据
  /// [format] 导出格式（如 'json', 'csv'）
  /// [startDate] 开始日期（可选）
  /// [endDate] 结束日期（可选）
  Future<String> exportDrafts(
    String format, 
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// 导入草稿数据
  /// [data] 要导入的数据
  /// [format] 数据格式
  /// 返回成功导入的草稿数量
  Future<int> importDrafts(String data, String format);
  
  /// 清空所有草稿数据
  Future<bool> clearAllDrafts();
  
  /// 获取草稿统计信息
  Future<DraftStatistics> getDraftStatistics();
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo();
}

/// 草稿统计信息
class DraftStatistics {
  final int totalDrafts;
  final int validDrafts;
  final int emptyDrafts;
  final int todayDrafts;
  final int thisWeekDrafts;
  final int thisMonthDrafts;
  final DateTime? oldestDraftDate;
  final DateTime? newestDraftDate;
  final double averageDraftsPerDay;
  final Map<String, int> draftsByCategory;
  
  const DraftStatistics({
    required this.totalDrafts,
    required this.validDrafts,
    required this.emptyDrafts,
    required this.todayDrafts,
    required this.thisWeekDrafts,
    required this.thisMonthDrafts,
    this.oldestDraftDate,
    this.newestDraftDate,
    required this.averageDraftsPerDay,
    required this.draftsByCategory,
  });
  
  /// 从Map创建DraftStatistics实例
  factory DraftStatistics.fromMap(Map<String, dynamic> map) {
    return DraftStatistics(
      totalDrafts: map['totalDrafts'] as int,
      validDrafts: map['validDrafts'] as int,
      emptyDrafts: map['emptyDrafts'] as int,
      todayDrafts: map['todayDrafts'] as int,
      thisWeekDrafts: map['thisWeekDrafts'] as int,
      thisMonthDrafts: map['thisMonthDrafts'] as int,
      oldestDraftDate: map['oldestDraftDate'] != null 
          ? DateTime.parse(map['oldestDraftDate'] as String) 
          : null,
      newestDraftDate: map['newestDraftDate'] != null 
          ? DateTime.parse(map['newestDraftDate'] as String) 
          : null,
      averageDraftsPerDay: (map['averageDraftsPerDay'] as num).toDouble(),
      draftsByCategory: Map<String, int>.from(map['draftsByCategory'] as Map),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalDrafts': totalDrafts,
      'validDrafts': validDrafts,
      'emptyDrafts': emptyDrafts,
      'todayDrafts': todayDrafts,
      'thisWeekDrafts': thisWeekDrafts,
      'thisMonthDrafts': thisMonthDrafts,
      'oldestDraftDate': oldestDraftDate?.toIso8601String(),
      'newestDraftDate': newestDraftDate?.toIso8601String(),
      'averageDraftsPerDay': averageDraftsPerDay,
      'draftsByCategory': draftsByCategory,
    };
  }
  
  /// 转换为JSON字符串
  String toJson() {
    return toMap().toString();
  }
}