import '../../domain/entities/task.dart';
import '../../domain/entities/focus_record.dart';
import '../../domain/entities/draft.dart';
import '../../domain/entities/export_record.dart';

/// 本地数据源接口
/// 定义所有本地数据访问操作的抽象接口
abstract class LocalDataSource {
  // ==================== 任务相关操作 ====================
  
  /// 获取所有任务
  Future<List<Task>> getAllTasks({int? limit, int? offset});
  
  /// 根据ID获取任务
  Future<Task?> getTaskById(int id);
  
  /// 创建任务
  Future<Task> createTask(Task task);
  
  /// 更新任务
  Future<Task> updateTask(Task task);
  
  /// 删除任务
  Future<bool> deleteTask(int id);
  
  /// 批量删除任务
  Future<int> deleteTasks(List<int> ids);
  
  /// 归档任务
  Future<Task> archiveTask(int id);
  
  /// 取消归档任务
  Future<Task> unarchiveTask(int id);
  
  /// 更新任务状态
  Future<Task> updateTaskStatus(int id, TaskStatus status);
  
  /// 更新任务优先级
  Future<Task> updateTaskPriority(int id, TaskPriority priority);
  
  /// 更新任务实际用时
  Future<Task> updateTaskActualMinutes(int id, int actualMinutes);
  
  /// 更新任务排序
  Future<bool> updateTasksOrder(List<int> taskIds);
  
  /// 按状态获取任务
  Future<List<Task>> getTasksByStatus(TaskStatus status, {int? limit, int? offset});
  
  /// 按优先级获取任务
  Future<List<Task>> getTasksByPriority(TaskPriority priority, {int? limit, int? offset});
  
  /// 按分类获取任务
  Future<List<Task>> getTasksByCategory(String category, {int? limit, int? offset});
  
  /// 按标签获取任务
  Future<List<Task>> getTasksByTag(String tag, {int? limit, int? offset});
  
  /// 按日期范围获取任务
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset});
  
  /// 搜索任务
  Future<List<Task>> searchTasks(String query, {int? limit, int? offset});
  
  /// 获取逾期任务
  Future<List<Task>> getOverdueTasks({int? limit, int? offset});
  
  /// 获取即将到期任务
  Future<List<Task>> getDueSoonTasks({int? limit, int? offset});
  
  /// 获取今天的任务
  Future<List<Task>> getTodayTasks({int? limit, int? offset});
  
  /// 获取本周的任务
  Future<List<Task>> getThisWeekTasks({int? limit, int? offset});
  
  /// 获取所有分类
  Future<List<String>> getAllCategories();
  
  /// 获取所有标签
  Future<List<String>> getAllTags();
  
  /// 清空所有任务数据
  Future<bool> clearAllTasks();
  
  // ==================== 专注记录相关操作 ====================
  
  /// 获取所有专注记录
  Future<List<FocusRecord>> getAllFocusRecords({int? limit, int? offset});
  
  /// 根据ID获取专注记录
  Future<FocusRecord?> getFocusRecordById(int id);
  
  /// 创建专注记录
  Future<FocusRecord> createFocusRecord(FocusRecord record);
  
  /// 更新专注记录
  Future<FocusRecord> updateFocusRecord(FocusRecord record);
  
  /// 删除专注记录
  Future<bool> deleteFocusRecord(int id);
  
  /// 批量删除专注记录
  Future<int> deleteFocusRecords(List<int> ids);
  
  /// 获取活跃的专注会话
  Future<FocusRecord?> getActiveFocusSession();
  
  /// 按任务获取专注记录
  Future<List<FocusRecord>> getFocusRecordsByTask(int taskId, {int? limit, int? offset});
  
  /// 按状态获取专注记录
  Future<List<FocusRecord>> getFocusRecordsByStatus(FocusSessionStatus status, {int? limit, int? offset});
  
  /// 按模式类型获取专注记录
  Future<List<FocusRecord>> getFocusRecordsByModeType(FocusModeType modeType, {int? limit, int? offset});
  
  /// 按日期范围获取专注记录
  Future<List<FocusRecord>> getFocusRecordsByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset});
  
  /// 获取今天的专注记录
  Future<List<FocusRecord>> getTodayFocusRecords({int? limit, int? offset});
  
  /// 获取本周的专注记录
  Future<List<FocusRecord>> getThisWeekFocusRecords({int? limit, int? offset});
  
  /// 获取本月的专注记录
  Future<List<FocusRecord>> getThisMonthFocusRecords({int? limit, int? offset});
  
  /// 获取已完成的专注记录
  Future<List<FocusRecord>> getCompletedFocusRecords({int? limit, int? offset});
  
  /// 获取被中断的专注记录
  Future<List<FocusRecord>> getInterruptedFocusRecords({int? limit, int? offset});
  
  /// 清理过期的专注记录
  Future<int> cleanupOldFocusRecords(int daysToKeep);
  
  /// 清空所有专注记录数据
  Future<bool> clearAllFocusRecords();
  
  // ==================== 草稿相关操作 ====================
  
  /// 获取所有草稿
  Future<List<Draft>> getAllDrafts({int? limit, int? offset});
  
  /// 根据ID获取草稿
  Future<Draft?> getDraftById(int id);
  
  /// 创建草稿
  Future<Draft> createDraft(Draft draft);
  
  /// 更新草稿
  Future<Draft> updateDraft(Draft draft);
  
  /// 删除草稿
  Future<bool> deleteDraft(int id);
  
  /// 批量删除草稿
  Future<int> deleteDrafts(List<int> ids);
  
  /// 获取最新草稿
  Future<List<Draft>> getLatestDrafts({int limit = 10});
  
  /// 搜索草稿
  Future<List<Draft>> searchDrafts(String query, {int? limit, int? offset});
  
  /// 按日期范围获取草稿
  Future<List<Draft>> getDraftsByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset});
  
  /// 获取今天的草稿
  Future<List<Draft>> getTodayDrafts({int? limit, int? offset});
  
  /// 获取本周的草稿
  Future<List<Draft>> getThisWeekDrafts({int? limit, int? offset});
  
  /// 清理过期草稿
  Future<int> cleanupOldDrafts(int daysToKeep);
  
  /// 获取空草稿
  Future<List<Draft>> getEmptyDrafts();
  
  /// 清理空草稿
  Future<int> cleanupEmptyDrafts();
  
  /// 清空所有草稿数据
  Future<bool> clearAllDrafts();
  
  // ==================== 导出记录相关操作 ====================
  
  /// 获取所有导出记录
  Future<List<ExportRecord>> getAllExportRecords({int? limit, int? offset});
  
  /// 根据ID获取导出记录
  Future<ExportRecord?> getExportRecordById(int id);
  
  /// 创建导出记录
  Future<ExportRecord> createExportRecord(ExportRecord record);
  
  /// 更新导出记录
  Future<ExportRecord> updateExportRecord(ExportRecord record);
  
  /// 删除导出记录
  Future<bool> deleteExportRecord(int id);
  
  /// 按类型获取导出记录
  Future<List<ExportRecord>> getExportRecordsByType(ExportType type, {int? limit, int? offset});
  
  /// 按范围获取导出记录
  Future<List<ExportRecord>> getExportRecordsByRange(ExportRange range, {int? limit, int? offset});
  
  /// 按状态获取导出记录
  Future<List<ExportRecord>> getExportRecordsByStatus(ExportStatus status, {int? limit, int? offset});
  
  /// 按日期范围获取导出记录
  Future<List<ExportRecord>> getExportRecordsByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset});
  
  /// 获取最新导出记录
  Future<List<ExportRecord>> getLatestExportRecords({int limit = 10});
  
  /// 获取成功的导出记录
  Future<List<ExportRecord>> getSuccessfulExportRecords({int? limit, int? offset});
  
  /// 获取失败的导出记录
  Future<List<ExportRecord>> getFailedExportRecords({int? limit, int? offset});
  
  /// 按类型和范围分组获取导出记录
  Future<Map<String, List<ExportRecord>>> getExportRecordsByTypeAndRange();
  
  /// 清理过期导出记录
  Future<int> cleanupOldExportRecords(int daysToKeep);
  
  /// 清理失败的导出记录
  Future<int> cleanupFailedExportRecords();
  
  /// 清空所有导出记录数据
  Future<bool> clearAllExportRecords();
  
  // ==================== 数据库管理操作 ====================
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo();
  
  /// 备份数据库
  Future<String> backupDatabase(String backupPath);
  
  /// 恢复数据库
  Future<bool> restoreDatabase(String backupPath);
  
  /// 验证数据完整性
  Future<Map<String, dynamic>> validateDataIntegrity();
  
  /// 修复数据完整性
  Future<Map<String, dynamic>> repairDataIntegrity();
  
  /// 清空所有数据
  Future<bool> clearAllData();
}