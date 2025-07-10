import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/focus_record_repository.dart';
import '../../domain/repositories/draft_repository.dart';
import '../../domain/repositories/export_record_repository.dart';
import '../../infrastructure/repositories/task_repository_impl.dart';
import '../../infrastructure/repositories/focus_record_repository_impl.dart';
import '../../infrastructure/repositories/draft_repository_impl.dart';
import '../../infrastructure/repositories/export_record_repository_impl.dart';
import '../../infrastructure/datasources/local_data_source.dart';
import '../../infrastructure/datasources/local_data_source_impl.dart';
import 'database_helper.dart';
import 'database_migration.dart';

/// 数据库服务类
/// 提供统一的数据访问入口，管理所有Repository和DataSource
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseHelper? _databaseHelper;
  static LocalDataSource? _localDataSource;
  
  // Repository实例
  late final TaskRepository _taskRepository;
  late final FocusRecordRepository _focusRecordRepository;
  late final DraftRepository _draftRepository;
  late final ExportRecordRepository _exportRecordRepository;
  
  /// 私有构造函数
  DatabaseService._internal();
  
  /// 获取单例实例
  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }
  
  /// 初始化数据库服务
  Future<void> initialize() async {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper.instance;
      await _databaseHelper!.database; // 确保数据库已初始化
      
      _localDataSource = LocalDataSourceImpl(_databaseHelper!);
      
      // 初始化Repository
      _taskRepository = TaskRepositoryImpl(_databaseHelper!);
      _focusRecordRepository = FocusRecordRepositoryImpl(_databaseHelper!);
      _draftRepository = DraftRepositoryImpl(_databaseHelper!);
      _exportRecordRepository = ExportRecordRepositoryImpl(_databaseHelper!);
    }
  }
  
  /// 获取任务仓库
  TaskRepository get taskRepository {
    _ensureInitialized();
    return _taskRepository;
  }
  
  /// 获取专注记录仓库
  FocusRecordRepository get focusRecordRepository {
    _ensureInitialized();
    return _focusRecordRepository;
  }
  
  /// 获取草稿仓库
  DraftRepository get draftRepository {
    _ensureInitialized();
    return _draftRepository;
  }
  
  /// 获取导出记录仓库
  ExportRecordRepository get exportRecordRepository {
    _ensureInitialized();
    return _exportRecordRepository;
  }
  
  /// 获取本地数据源
  LocalDataSource get localDataSource {
    _ensureInitialized();
    return _localDataSource!;
  }
  
  /// 获取数据库助手
  DatabaseHelper get databaseHelper {
    _ensureInitialized();
    return _databaseHelper!;
  }
  
  /// 确保服务已初始化
  void _ensureInitialized() {
    if (_databaseHelper == null) {
      throw StateError('DatabaseService未初始化，请先调用initialize()');
    }
  }
  
  // ==================== 数据库管理操作 ====================
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    _ensureInitialized();
    return await _databaseHelper!.getDatabaseInfo();
  }
  
  /// 备份数据库
  Future<String> backupDatabase(String backupPath) async {
    _ensureInitialized();
    return await _databaseHelper!.backupDatabase(backupPath);
  }
  
  /// 恢复数据库
  Future<bool> restoreDatabase(String backupPath) async {
    _ensureInitialized();
    return await _databaseHelper!.restoreDatabase(backupPath);
  }
  
  /// 验证数据完整性
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    _ensureInitialized();
    return await _databaseHelper!.validateDataIntegrity();
  }
  
  /// 修复数据完整性
  Future<Map<String, dynamic>> repairDataIntegrity() async {
    _ensureInitialized();
    final success = await _databaseHelper!.repairDataIntegrity();
    return {
      'success': success,
      'repairedAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// 清空所有数据
  Future<bool> clearAllData() async {
    _ensureInitialized();
    try {
      await _databaseHelper!.clearAllData();
      return true;
    } catch (e) {
      print('清空数据失败: $e');
      return false;
    }
  }
  
  /// 关闭数据库连接
  Future<void> close() async {
    if (_databaseHelper != null) {
      await _databaseHelper!.close();
      _databaseHelper = null;
      _localDataSource = null;
      _instance = null;
    }
  }
  
  // ==================== 数据库升级管理 ====================
  
  /// 检查是否需要升级
  Future<bool> needsUpgrade() async {
    _ensureInitialized();
    final dbInfo = await getDatabaseInfo();
    final currentVersion = dbInfo['version'] as int;
    final migration = DatabaseMigration();
    return await migration.needsUpgrade(
      await _databaseHelper!.database,
      currentVersion,
      DatabaseMigration.currentVersion,
    );
  }
  
  /// 获取升级步骤
  Future<List<String>> getUpgradeSteps() async {
    _ensureInitialized();
    final dbInfo = await getDatabaseInfo();
    final currentVersion = dbInfo['version'] as int;
    final migration = DatabaseMigration();
    return await migration.getUpgradeSteps(
      currentVersion, 
      DatabaseMigration.currentVersion,
    );
  }
  
  /// 执行数据库升级
  Future<bool> performUpgrade({String? backupPath}) async {
    _ensureInitialized();
    
    try {
      final db = await _databaseHelper!.database;
      final dbInfo = await getDatabaseInfo();
      final currentVersion = dbInfo['version'] as int;
      
      final migration = DatabaseMigration();
      if (!await migration.needsUpgrade(
        db,
        currentVersion,
        DatabaseMigration.currentVersion,
      )) {
        return true; // 无需升级
      }
      
      // 升级前备份
      if (backupPath != null) {
        await migration.backupBeforeUpgradeInstance(db, backupPath);
      }
      
      // 执行升级
      await migration.onUpgrade(
        db, 
        currentVersion, 
        DatabaseMigration.currentVersion,
      );
      
      // 验证升级结果
      final isValid = await migration.validateUpgradeInstance(db);
      if (!isValid) {
        // 升级验证失败，尝试回滚
        if (backupPath != null) {
          await migration.rollbackUpgradeInstance(db, backupPath);
        }
        return false;
      }
      
      return true;
    } catch (e) {
      print('数据库升级失败: $e');
      return false;
    }
  }
  
  /// 获取升级历史
  Future<List<Map<String, dynamic>>> getUpgradeHistory() async {
    _ensureInitialized();
    final db = await _databaseHelper!.database;
    final migration = DatabaseMigration();
    return await migration.getUpgradeHistoryInstance(db);
  }
  
  /// 清理升级记录
  Future<void> cleanupUpgradeHistory({int keepDays = 30}) async {
    _ensureInitialized();
    final db = await _databaseHelper!.database;
    final migration = DatabaseMigration();
    await migration.cleanupUpgradeHistoryInstance(db, daysToKeep: keepDays);
  }
  
  // ==================== 统计信息 ====================
  
  /// 获取综合统计信息
  Future<Map<String, dynamic>> getComprehensiveStats() async {
    _ensureInitialized();
    
    final taskStats = await _taskRepository.getTaskStatistics();
    final focusStats = await _focusRecordRepository.getFocusStatistics();
    final draftStats = await _draftRepository.getDraftStatistics();
    final exportStats = await _exportRecordRepository.getExportStatistics();
    final dbInfo = await getDatabaseInfo();
    
    return {
      'database': dbInfo,
      'tasks': {
        'total': taskStats.totalTasks,
        'completed': taskStats.completedTasks,
        'pending': taskStats.pendingTasks,
        'in_progress': taskStats.inProgressTasks,
        'overdue': taskStats.overdueTasks,
      },
      'focus': {
        'total_sessions': focusStats.totalSessions,
        'completed_sessions': focusStats.completedSessions,
        'total_minutes': focusStats.totalFocusMinutes,
        'average_session': focusStats.averageSessionMinutes,
        'completion_rate': focusStats.completionRate,
      },
      'drafts': {
        'total': draftStats.totalDrafts,
        'valid': draftStats.validDrafts,
        'empty': draftStats.emptyDrafts,
        'today': draftStats.todayDrafts,
      },
      'exports': {
        'total': exportStats.totalExports,
        'successful': exportStats.successfulExports,
        'failed': exportStats.failedExports,
        'success_rate': exportStats.successRate,
      },
    };
  }
  
  /// 获取数据库健康状态
  Future<Map<String, dynamic>> getDatabaseHealth() async {
    _ensureInitialized();
    
    final integrity = await validateDataIntegrity();
    final dbInfo = await getDatabaseInfo();
    final stats = await getComprehensiveStats();
    
    // 计算健康分数
    double healthScore = 100.0;
    final issues = <String>[];
    
    // 检查数据完整性
    if (integrity['orphaned_focus_records'] > 0) {
      healthScore -= 10;
      issues.add('发现 ${integrity['orphaned_focus_records']} 条孤立的专注记录');
    }
    
    if (integrity['invalid_tasks'] > 0) {
      healthScore -= 10;
      issues.add('发现 ${integrity['invalid_tasks']} 条无效的任务记录');
    }
    
    // 检查数据库大小
    final dbSize = dbInfo['size_mb'] as double;
    if (dbSize > 100) {
      healthScore -= 5;
      issues.add('数据库文件较大 (${dbSize.toStringAsFixed(2)} MB)');
    }
    
    // 检查导出失败率
    final exportStats = stats['exports'] as Map<String, dynamic>;
    final failureRate = 100 - (exportStats['success_rate'] as double);
    if (failureRate > 20) {
      healthScore -= 15;
      issues.add('导出失败率较高 (${failureRate.toStringAsFixed(1)}%)');
    }
    
    // 确保分数不低于0
    healthScore = healthScore.clamp(0.0, 100.0);
    
    return {
      'health_score': healthScore,
      'status': _getHealthStatus(healthScore),
      'issues': issues,
      'recommendations': _getHealthRecommendations(healthScore, issues),
      'last_check': DateTime.now().toIso8601String(),
    };
  }
  
  /// 获取健康状态描述
  String _getHealthStatus(double score) {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 70) return '一般';
    if (score >= 60) return '较差';
    return '糟糕';
  }
  
  /// 获取健康建议
  List<String> _getHealthRecommendations(double score, List<String> issues) {
    final recommendations = <String>[];
    
    if (score < 80) {
      recommendations.add('建议执行数据完整性修复');
    }
    
    if (issues.any((issue) => issue.contains('孤立'))) {
      recommendations.add('清理孤立的专注记录');
    }
    
    if (issues.any((issue) => issue.contains('无效'))) {
      recommendations.add('修复无效的任务数据');
    }
    
    if (issues.any((issue) => issue.contains('较大'))) {
      recommendations.add('考虑清理历史数据或压缩数据库');
    }
    
    if (issues.any((issue) => issue.contains('失败率'))) {
      recommendations.add('检查导出功能配置');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('数据库状态良好，继续保持');
    }
    
    return recommendations;
  }
}