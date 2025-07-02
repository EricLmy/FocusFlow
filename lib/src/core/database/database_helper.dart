import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类 - 单例模式管理SQLite数据库
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
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'focus_flow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建任务表
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        plan_start_time DATETIME,
        due_time DATETIME,
        priority INTEGER DEFAULT 1 CHECK (priority IN (0, 1, 2)),
        progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
        status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'paused', 'done'))
      )
    ''');

    // 创建专注记录表
    await db.execute('''
      CREATE TABLE focus_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        start_time DATETIME NOT NULL,
        end_time DATETIME NOT NULL,
        duration INTEGER NOT NULL CHECK (duration >= 0),
        interrupted BOOLEAN DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // 创建任务草稿表
    await db.execute('''
      CREATE TABLE drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_data TEXT NOT NULL,
        save_time DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 创建统计导出表
    await db.execute('''
      CREATE TABLE export_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        export_type TEXT NOT NULL CHECK (export_type IN ('csv', 'xlsx')),
        export_scope TEXT NOT NULL CHECK (export_scope IN ('day', 'week', 'month', 'all')),
        export_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        file_path TEXT NOT NULL,
        status TEXT DEFAULT 'success' CHECK (status IN ('success', 'failed')),
        error_msg TEXT
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_priority ON tasks(priority)');
    await db.execute('CREATE INDEX idx_focus_records_task_id ON focus_records(task_id)');
    await db.execute('CREATE INDEX idx_focus_records_start_time ON focus_records(start_time)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 根据版本号进行数据库升级
    if (oldVersion < 2) {
      // 示例：添加新字段或表
      // await db.execute('ALTER TABLE tasks ADD COLUMN new_field TEXT');
    }
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
      await txn.delete('export_records');
      await txn.delete('focus_records');
      await txn.delete('drafts');
      await txn.delete('tasks');
    });
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
    
    return {
      'taskCount': taskCount,
      'focusRecordCount': focusRecordCount,
      'databasePath': db.path,
    };
  }
}