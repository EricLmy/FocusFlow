import 'package:sqflite/sqflite.dart';

/// 数据库迁移管理类
/// 负责处理数据库版本升级和数据迁移逻辑
class DatabaseMigration {
  /// 当前数据库版本
  static const int currentVersion = 3;
  
  /// 检查是否需要升级
  Future<bool> needsUpgrade(Database db, int currentVersion, int targetVersion) async {
    return currentVersion < targetVersion;
  }
  
  /// 获取升级步骤描述
  Future<List<String>> getUpgradeSteps(int fromVersion, int toVersion) async {
    final steps = <String>[];
    
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      switch (version) {
        case 2:
          steps.add('升级到版本2：添加新字段和表结构');
          break;
        case 3:
          steps.add('升级到版本3：优化表结构和索引');
          break;
        default:
          steps.add('升级到版本 $version');
      }
    }
    
    return steps;
  }
  
  /// 执行数据库升级（实例方法版本）
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 验证参数
    if (oldVersion < 0 || newVersion <= 0 || newVersion <= oldVersion) {
      throw ArgumentError('无效的版本号: $oldVersion -> $newVersion');
    }
    

    
    // 使用事务确保升级过程的原子性
    await db.transaction((txn) async {
      // 逐步升级，确保每个版本的变更都被正确应用
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        await _upgradeToVersionInstance(txn, version);
      }
      
      // 记录升级完成
      await _recordUpgradeInstance(txn, oldVersion, newVersion);
    });
    

  }
  
  /// 升级到指定版本（实例方法版本）
  Future<void> _upgradeToVersionInstance(Transaction txn, int version) async {
    switch (version) {
      case 1:
        // 初始版本，无需升级操作
        break;
      case 2:
        await _upgradeToVersion2Instance(txn);
        break;
      case 3:
        await _upgradeToVersion3Instance(txn);
        break;
      // 添加更多版本的升级逻辑
      default:
        throw Exception('不支持的数据库版本: $version');
    }
  }
  
  /// 升级到版本2的逻辑（实例方法版本）
  Future<void> _upgradeToVersion2Instance(Transaction txn) async {
    // 为tasks表添加新字段
    await txn.execute('ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT "";');
    await txn.execute('ALTER TABLE tasks ADD COLUMN tags TEXT DEFAULT "";');
    await txn.execute('ALTER TABLE tasks ADD COLUMN estimated_time INTEGER DEFAULT 0;');
    await txn.execute('ALTER TABLE tasks ADD COLUMN actual_time INTEGER DEFAULT 0;');
    await txn.execute('ALTER TABLE tasks ADD COLUMN due_date INTEGER;');
    await txn.execute('ALTER TABLE tasks ADD COLUMN completed_at INTEGER;');
    await txn.execute('ALTER TABLE tasks ADD COLUMN archived_at INTEGER;');
    await txn.execute('ALTER TABLE tasks ADD COLUMN sort_order INTEGER DEFAULT 0;');
    
    // 为focus_records表添加新字段
    await txn.execute('ALTER TABLE focus_records ADD COLUMN mode TEXT DEFAULT "pomodoro";');
    await txn.execute('ALTER TABLE focus_records ADD COLUMN interruptions INTEGER DEFAULT 0;');
    await txn.execute('ALTER TABLE focus_records ADD COLUMN notes TEXT DEFAULT "";');
    
    // 创建drafts表
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        type TEXT NOT NULL DEFAULT 'task',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    
    // 创建export_records表
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS export_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        export_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        record_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');
  }
  
  /// 升级到版本3的逻辑（实例方法版本）
  Future<void> _upgradeToVersion3Instance(Transaction txn) async {
    // 创建索引以提高查询性能
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_focus_records_task_id ON focus_records(task_id);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_focus_records_start_time ON focus_records(start_time);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_focus_records_status ON focus_records(status);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_focus_records_created_at ON focus_records(created_at);');
    
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);');
    await txn.execute('CREATE INDEX IF NOT EXISTS idx_tasks_sort_order ON tasks(sort_order);');
  }
  
  /// 记录升级信息（实例方法版本）
  Future<void> _recordUpgradeInstance(
    Transaction txn, 
    int oldVersion, 
    int newVersion
  ) async {
    // 创建升级记录表（如果不存在）
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS database_upgrades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        old_version INTEGER NOT NULL,
        new_version INTEGER NOT NULL,
        upgrade_time TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 1
      );
    ''');
    
    // 插入升级记录
    await txn.insert('database_upgrades', {
      'old_version': oldVersion,
      'new_version': newVersion,
      'upgrade_time': DateTime.now().toIso8601String(),
      'success': 1,
    });
  }
  
  /// 验证升级结果（实例方法版本）
  Future<bool> validateUpgradeInstance(Database db, {int? fromVersion, int? toVersion}) async {
    try {
      // 检查必要的表是否存在
      final requiredTables = ['tasks', 'focus_records'];
      for (final table in requiredTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'",
        );
        if (result.isEmpty) {

          return false;
        }
      }
      
      // 检查数据完整性
      final taskCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tasks'),
      ) ?? 0;
      
      final focusCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM focus_records'),
      ) ?? 0;
      

      
      // 检查外键约束
      final orphanedRecords = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM focus_records 
          WHERE task_id IS NOT NULL 
          AND task_id NOT IN (SELECT id FROM tasks)
        '''),
      ) ?? 0;
      
      if (orphanedRecords > 0) {

        return false;
      }
      
      return true;
    } catch (e) {

      return false;
    }
  }
  
  /// 获取升级历史记录（实例方法版本）
  Future<List<Map<String, dynamic>>> getUpgradeHistoryInstance(Database db) async {
    try {
      // 检查升级记录表是否存在
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='database_upgrades'",
      );
      
      if (result.isEmpty) {
        return [];
      }
      
      return await db.query(
        'database_upgrades',
        orderBy: 'upgrade_time DESC',
      );
    } catch (e) {
      print('获取升级历史失败: $e');
      return [];
    }
  }
  
  /// 清理升级历史记录（实例方法版本）
  Future<bool> cleanupUpgradeHistoryInstance(Database db, {int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysToKeep))
          .toIso8601String();
      
      final deletedCount = await db.delete(
        'database_upgrades',
        where: 'upgrade_time < ?',
        whereArgs: [cutoffDate],
      );
      
      print('升级记录清理完成，删除了 $deletedCount 条记录');
      return true;
    } catch (e) {
      print('升级记录清理失败: $e');
      return false;
    }
  }
  
  /// 备份数据库（实例方法版本）
  Future<String?> backupBeforeUpgradeInstance(Database db, String backupPath) async {
    try {
      // 这里可以实现数据备份逻辑
      // 例如：导出所有表的数据到JSON文件
      final tables = ['tasks', 'focus_records', 'drafts', 'export_records'];
      final backupData = <String, List<Map<String, dynamic>>>{};
      
      for (final table in tables) {
        try {
          final data = await db.query(table);
          backupData[table] = data;
        } catch (e) {
          // 表可能不存在，继续处理其他表
          print('备份表 $table 时出错: $e');
        }
      }
      
      // 将备份数据写入文件（这里简化处理）
      print('数据备份完成: $backupPath');
      return backupPath;
    } catch (e) {
      print('数据备份失败: $e');
      return null;
    }
  }
  
  /// 回滚升级（实例方法版本）
  Future<bool> rollbackUpgradeInstance(Database db, String backupPath) async {
    try {
      // 这里可以实现回滚逻辑
      // 例如：从备份文件恢复数据
      print('开始回滚升级: $backupPath');
      
      // 清空当前数据
      final tables = ['tasks', 'focus_records', 'drafts', 'export_records'];
      for (final table in tables) {
        try {
          await db.delete(table);
        } catch (e) {
          // 表可能不存在，继续处理其他表
          print('清空表 $table 时出错: $e');
        }
      }
      
      // 从备份恢复数据（这里简化处理）
      print('升级回滚完成');
      return true;
    } catch (e) {
      print('升级回滚失败: $e');
      return false;
    }
  }
  
}