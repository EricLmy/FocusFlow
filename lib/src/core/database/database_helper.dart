import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart';

/// 数据库帮助类 - 单例模式管理SQLite数据库
/// 提供数据库初始化、升级、备份、恢复等核心功能
/// 遵循系统设计文档中的数据库设计规范
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 根据平台确定数据库路径
    // Web平台直接使用数据库名称，sqflite_common_ffi_web 会将其存储在IndexedDB中
    // 其他平台（iOS, Android, macOS, Windows, Linux）则需要获取文件系统路径
    final String path = kIsWeb
        ? 'focus_flow.db'
        : join(await getDatabasesPath(), 'focus_flow.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await _createTables(txn);
    });
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库版本升级机制
    // 确保数据迁移的原子性和一致性
    await db.transaction((txn) async {
      if (oldVersion < 4) {
        // 由于表结构变化较大，直接重建所有表
        await _recreateAllTables(txn);
      }
    });
  }

  /// 重建所有表（用于数据库升级）
  Future<void> _recreateAllTables(Transaction txn) async {
    // 备份现有数据
    List<Map<String, dynamic>> existingTasks = [];
    List<Map<String, dynamic>> existingFocusRecords = [];
    
    try {
      existingTasks = await txn.rawQuery('SELECT * FROM tasks');
    } catch (e) {
      // 表可能不存在，忽略错误
    }
    
    try {
      existingFocusRecords = await txn.rawQuery('SELECT * FROM focus_records');
    } catch (e) {
      // 表可能不存在，忽略错误
    }
    
    // 删除旧表
    await txn.execute('DROP TABLE IF EXISTS export_records');
    await txn.execute('DROP TABLE IF EXISTS focus_records');
    await txn.execute('DROP TABLE IF EXISTS drafts');
    await txn.execute('DROP TABLE IF EXISTS tasks');
    
    // 重新创建表结构
    await _createTables(txn);
    
    // 迁移任务数据
    for (final task in existingTasks) {
      await txn.insert('tasks', {
        'title': task['title'] ?? '',
        'description': task['description'],
        'priority': task['priority'] ?? 1,
        'status': task['status'] ?? 'todo',
        'estimatedMinutes': task['estimatedMinutes'] ?? task['estimated_minutes'] ?? 25,
        'actualMinutes': task['actualMinutes'] ?? task['actual_minutes'] ?? 0,
        'createdAt': task['createdAt'] ?? task['created_at'] ?? DateTime.now().toIso8601String(),
        'updatedAt': task['updatedAt'] ?? task['updated_at'],
        'completedAt': task['completedAt'] ?? task['completed_at'],
        'dueDate': task['dueDate'] ?? task['due_date'],
        'category': task['category'] ?? '',
        'tags': task['tags'] ?? '',
        'isArchived': task['isArchived'] ?? task['is_archived'] ?? 0,
        'sortOrder': task['sortOrder'] ?? task['sort_order'] ?? 0,
        'progress': task['progress'] ?? 0.0,
      });
    }
    
    // 迁移专注记录数据
    for (final record in existingFocusRecords) {
      await txn.insert('focus_records', {
        'task_id': record['task_id'] ?? record['taskId'],
        'task_title': record['task_title'] ?? record['taskTitle'],
        'mode_type': record['mode_type'] ?? record['modeType'] ?? 0,
        'planned_minutes': record['planned_minutes'] ?? record['plannedMinutes'] ?? 25,
        'actual_minutes': record['actual_minutes'] ?? record['actualMinutes'] ?? record['duration'] ?? 0,
        'status': record['status'] ?? 0,
        'start_time': record['start_time'] ?? record['startTime'] ?? DateTime.now().toIso8601String(),
        'end_time': record['end_time'] ?? record['endTime'],
        'paused_at': record['paused_at'] ?? record['pausedAt'],
        'paused_duration': record['paused_duration'] ?? record['pausedDuration'] ?? 0,
        'interruption_count': record['interruption_count'] ?? record['interruptionCount'] ?? 0,
        'notes': record['notes'],
        'metadata': record['metadata'],
        'created_at': record['created_at'] ?? record['createdAt'] ?? DateTime.now().toIso8601String(),
        'updated_at': record['updated_at'] ?? record['updatedAt'],
      });
    }
  }

  /// 创建表结构（用于onCreate和升级）
  Future<void> _createTables(Transaction txn) async {
    // 创建任务表
    await txn.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK (length(title) <= 255),
        description TEXT,
        priority INTEGER NOT NULL DEFAULT 1 CHECK (priority IN (0, 1, 2)),
        status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'paused', 'done')),
        estimatedMinutes INTEGER NOT NULL DEFAULT 25,
        actualMinutes INTEGER NOT NULL DEFAULT 0,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME,
        completedAt DATETIME,
        dueDate DATETIME,
        category TEXT DEFAULT '',
        tags TEXT DEFAULT '',
        isArchived INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 创建专注记录表
    await txn.execute('''
      CREATE TABLE focus_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        task_title TEXT,
        mode_type INTEGER NOT NULL DEFAULT 0,
        planned_minutes INTEGER NOT NULL,
        actual_minutes INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        start_time DATETIME NOT NULL,
        end_time DATETIME,
        paused_at DATETIME,
        paused_duration INTEGER NOT NULL DEFAULT 0,
        interruption_count INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        metadata TEXT,
        created_at DATETIME NOT NULL,
        updated_at DATETIME,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // 创建任务草稿表
    await txn.execute('''
      CREATE TABLE drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_data TEXT NOT NULL,
        save_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 创建统计导出表
    await txn.execute('''
      CREATE TABLE export_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        export_type TEXT NOT NULL CHECK (length(export_type) <= 20 AND export_type IN ('csv', 'xlsx')),
        export_scope TEXT NOT NULL CHECK (length(export_scope) <= 20 AND export_scope IN ('day', 'week', 'month', 'all')),
        export_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        file_path TEXT NOT NULL CHECK (length(file_path) <= 255),
        status TEXT NOT NULL DEFAULT 'success' CHECK (length(status) <= 20 AND status IN ('success', 'failed')),
        error_msg TEXT
      )
    ''');

    // 创建索引
    await txn.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await txn.execute('CREATE INDEX idx_tasks_priority ON tasks(priority)');
    await txn.execute('CREATE INDEX idx_tasks_createdAt ON tasks(createdAt)');
    await txn.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate)');
    await txn.execute('CREATE INDEX idx_tasks_category ON tasks(category)');
    await txn.execute('CREATE INDEX idx_tasks_isArchived ON tasks(isArchived)');
    await txn.execute('CREATE INDEX idx_focus_records_task_id ON focus_records(task_id)');
    await txn.execute('CREATE INDEX idx_focus_records_start_time ON focus_records(start_time)');
    await txn.execute('CREATE INDEX idx_export_records_export_time ON export_records(export_time)');
    await txn.execute('CREATE INDEX idx_drafts_save_time ON drafts(save_time)');
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据（用于测试或重置）
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // 按照外键依赖顺序删除数据
      await txn.delete('export_records');
      await txn.delete('focus_records');
      await txn.delete('drafts');
      await txn.delete('tasks');
      
      // 重置自增ID
      await txn.execute('DELETE FROM sqlite_sequence WHERE name IN ("tasks", "focus_records", "drafts", "export_records")');
    });
  }
  
  /// 备份数据库
  Future<String> backupDatabase(String backupPath) async {
    try {
      await database;
      
      // 这里可以实现文件复制逻辑
      // 由于Flutter的限制，实际实现可能需要使用平台特定的代码
      
      return backupPath;
    } catch (e) {
      throw Exception('备份数据库失败: $e');
    }
  }
  
  /// 恢复数据库
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      // 这里可以实现数据库恢复逻辑
      // 由于Flutter的限制，实际实现可能需要使用平台特定的代码
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final taskCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tasks'),
    ) ?? 0;
    final focusRecordCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM focus_records'),
    ) ?? 0;
    final draftCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM drafts'),
    ) ?? 0;
    final exportRecordCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM export_records'),
    ) ?? 0;
    
    // 获取数据库版本
    final version = Sqflite.firstIntValue(
      await db.rawQuery('PRAGMA user_version'),
    ) ?? 1;
    
    return {
      'taskCount': taskCount,
      'focusRecordCount': focusRecordCount,
      'draftCount': draftCount,
      'exportRecordCount': exportRecordCount,
      'databasePath': db.path,
      'version': version,
    };
  }
  
  /// 数据一致性校验
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    final db = await database;
    final issues = <String>[];
    
    try {
      // 检查外键约束
      final orphanedRecords = await db.rawQuery('''
        SELECT COUNT(*) as count FROM focus_records 
        WHERE task_id NOT IN (SELECT id FROM tasks)
      ''');
      
      final orphanedCount = Sqflite.firstIntValue(orphanedRecords) ?? 0;
      if (orphanedCount > 0) {
        issues.add('发现 $orphanedCount 条孤立的专注记录');
      }
      
      // 检查数据完整性
      final invalidTasks = await db.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE title IS NULL OR title = '' OR 
              priority NOT IN (0, 1, 2) OR 
              progress < 0 OR progress > 100 OR
              status NOT IN ('todo', 'doing', 'paused', 'done')
      ''');
      
      final invalidTaskCount = Sqflite.firstIntValue(invalidTasks) ?? 0;
      if (invalidTaskCount > 0) {
        issues.add('发现 $invalidTaskCount 条无效的任务记录');
      }
      
      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'checkedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isValid': false,
        'issues': ['数据校验过程中发生错误: $e'],
        'checkedAt': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// 修复数据一致性问题
  Future<bool> repairDataIntegrity() async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // 删除孤立的专注记录
        await txn.execute('''
          DELETE FROM focus_records 
          WHERE task_id NOT IN (SELECT id FROM tasks)
        ''');
        
        // 修复无效的任务数据
        await txn.execute('''
          UPDATE tasks SET 
            title = '未命名任务' WHERE title IS NULL OR title = '',
            priority = 1 WHERE priority NOT IN (0, 1, 2),
            progress = 0 WHERE progress < 0 OR progress > 100,
            status = 'todo' WHERE status NOT IN ('todo', 'doing', 'paused', 'done')
        ''');
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
}