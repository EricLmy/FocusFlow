import 'package:json_annotation/json_annotation.dart';

part 'export_record.g.dart';

/// 导出类型枚举
enum ExportType {
  @JsonValue('csv')
  csv,
  @JsonValue('xlsx')
  xlsx,
}

/// 导出范围枚举
enum ExportScope {
  @JsonValue('day')
  day,
  @JsonValue('week')
  week,
  @JsonValue('month')
  month,
  @JsonValue('all')
  all,
}

/// 导出范围枚举（兼容性别名）
typedef ExportRange = ExportScope;

/// 导出状态枚举
enum ExportStatus {
  @JsonValue('success')
  success,
  @JsonValue('failed')
  failed,
}

/// 导出记录实体类
/// 用于记录统计数据的导出历史
@JsonSerializable()
class ExportRecord {
  final int? id;
  final ExportType exportType;
  final ExportScope exportScope;
  final DateTime exportTime;
  final String filePath;
  final ExportStatus status;
  final String? errorMsg;
  
  const ExportRecord({
    this.id,
    required this.exportType,
    required this.exportScope,
    required this.exportTime,
    required this.filePath,
    this.status = ExportStatus.success,
    this.errorMsg,
  });
  
  /// 从JSON创建ExportRecord实例
  factory ExportRecord.fromJson(Map<String, dynamic> json) => _$ExportRecordFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ExportRecordToJson(this);
  
  /// 从数据库Map创建ExportRecord实例
  factory ExportRecord.fromMap(Map<String, dynamic> map) {
    return ExportRecord(
      id: map['id'] as int?,
      exportType: _parseExportType(map['export_type'] as String),
      exportScope: _parseExportScope(map['export_scope'] as String),
      exportTime: DateTime.parse(map['export_time'] as String),
      filePath: map['file_path'] as String,
      status: _parseExportStatus(map['status'] as String),
      errorMsg: map['error_msg'] as String?,
    );
  }
  
  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'export_type': exportType.name,
      'export_scope': exportScope.name,
      'export_time': exportTime.toIso8601String(),
      'file_path': filePath,
      'status': status.name,
      'error_msg': errorMsg,
    };
  }

  /// 从数据库Map创建ExportRecord实例（兼容数据库字段名）
  factory ExportRecord.fromDatabaseMap(Map<String, dynamic> map) {
    return ExportRecord(
      id: map['id'] as int?,
      exportType: _parseExportType(map['exportType'] as String? ?? map['export_type'] as String),
      exportScope: _parseExportScope(map['exportScope'] as String? ?? map['export_scope'] as String),
      exportTime: map['exportTime'] != null 
          ? DateTime.parse(map['exportTime'] as String)
          : DateTime.parse(map['export_time'] as String),
      filePath: map['filePath'] as String? ?? map['file_path'] as String,
      status: _parseExportStatus(map['status'] as String),
      errorMsg: map['errorMsg'] as String? ?? map['error_msg'] as String?,
    );
  }

  /// 转换为数据库Map（兼容数据库字段名）
  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'exportType': exportType.name,
      'exportScope': exportScope.name,
      'exportTime': exportTime.toIso8601String(),
      'filePath': filePath,
      'status': status.name,
      'errorMsg': errorMsg,
    };
  }
  
  /// 解析导出类型
  static ExportType _parseExportType(String value) {
    switch (value) {
      case 'csv':
        return ExportType.csv;
      case 'xlsx':
        return ExportType.xlsx;
      default:
        throw ArgumentError('Unknown export type: $value');
    }
  }
  
  /// 解析导出范围
  static ExportScope _parseExportScope(String value) {
    switch (value) {
      case 'day':
        return ExportScope.day;
      case 'week':
        return ExportScope.week;
      case 'month':
        return ExportScope.month;
      case 'all':
        return ExportScope.all;
      default:
        throw ArgumentError('Unknown export scope: $value');
    }
  }
  
  /// 解析导出状态
  static ExportStatus _parseExportStatus(String value) {
    switch (value) {
      case 'success':
        return ExportStatus.success;
      case 'failed':
        return ExportStatus.failed;
      default:
        throw ArgumentError('Unknown export status: $value');
    }
  }
  
  /// 复制并修改导出记录
  ExportRecord copyWith({
    int? id,
    ExportType? exportType,
    ExportScope? exportScope,
    DateTime? exportTime,
    String? filePath,
    ExportStatus? status,
    String? errorMsg,
  }) {
    return ExportRecord(
      id: id ?? this.id,
      exportType: exportType ?? this.exportType,
      exportScope: exportScope ?? this.exportScope,
      exportTime: exportTime ?? this.exportTime,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      errorMsg: errorMsg ?? this.errorMsg,
    );
  }
  
  /// 标记为成功
  ExportRecord markAsSuccess() {
    return copyWith(
      status: ExportStatus.success,
      errorMsg: null,
    );
  }
  
  /// 标记为失败
  ExportRecord markAsFailed(String errorMessage) {
    return copyWith(
      status: ExportStatus.failed,
      errorMsg: errorMessage,
    );
  }
  
  /// 检查是否成功
  bool get isSuccess => status == ExportStatus.success;
  
  /// 检查是否失败
  bool get isFailed => status == ExportStatus.failed;
  
  /// 获取导出类型显示文本
  String get exportTypeText {
    switch (exportType) {
      case ExportType.csv:
        return 'CSV';
      case ExportType.xlsx:
        return 'Excel';
    }
  }
  
  /// 获取导出范围显示文本
  String get exportScopeText {
    switch (exportScope) {
      case ExportScope.day:
        return '今日';
      case ExportScope.week:
        return '本周';
      case ExportScope.month:
        return '本月';
      case ExportScope.all:
        return '全部';
    }
  }
  
  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case ExportStatus.success:
        return '成功';
      case ExportStatus.failed:
        return '失败';
    }
  }
  
  /// 获取文件名
  String get fileName {
    return filePath.split('/').last;
  }
  
  /// 获取文件扩展名
  String get fileExtension {
    return fileName.split('.').last;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportRecord && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'ExportRecord(id: $id, type: $exportType, scope: $exportScope, status: $status)';
  }
}

/// 导出记录扩展方法
extension ExportRecordExtensions on List<ExportRecord> {
  /// 按导出时间排序
  List<ExportRecord> sortByExportTime({bool ascending = false}) {
    final sorted = List<ExportRecord>.from(this);
    sorted.sort((a, b) => ascending 
        ? a.exportTime.compareTo(b.exportTime)
        : b.exportTime.compareTo(a.exportTime));
    return sorted;
  }
  
  /// 筛选成功的记录
  List<ExportRecord> get successful {
    return where((record) => record.isSuccess).toList();
  }
  
  /// 筛选失败的记录
  List<ExportRecord> get failed {
    return where((record) => record.isFailed).toList();
  }
  
  /// 按导出类型筛选
  List<ExportRecord> filterByType(ExportType type) {
    return where((record) => record.exportType == type).toList();
  }
  
  /// 按导出范围筛选
  List<ExportRecord> filterByScope(ExportScope scope) {
    return where((record) => record.exportScope == scope).toList();
  }
  
  /// 筛选特定日期范围的记录
  List<ExportRecord> filterByDateRange(DateTime start, DateTime end) {
    return where((record) => 
        record.exportTime.isAfter(start) && record.exportTime.isBefore(end)
    ).toList();
  }
  
  /// 获取最新的导出记录
  ExportRecord? get latest {
    if (isEmpty) return null;
    return sortByExportTime().first;
  }
  
  /// 清理过期的导出记录（超过指定天数）
  List<ExportRecord> cleanupOldRecords({int daysToKeep = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return where((record) => record.exportTime.isAfter(cutoffDate)).toList();
  }
  
  /// 按导出类型分组
  Map<ExportType, List<ExportRecord>> groupByType() {
    final Map<ExportType, List<ExportRecord>> grouped = {};
    for (final record in this) {
      grouped.putIfAbsent(record.exportType, () => []).add(record);
    }
    return grouped;
  }
  
  /// 按导出范围分组
  Map<ExportScope, List<ExportRecord>> groupByScope() {
    final Map<ExportScope, List<ExportRecord>> grouped = {};
    for (final record in this) {
      grouped.putIfAbsent(record.exportScope, () => []).add(record);
    }
    return grouped;
  }
}