import 'package:json_annotation/json_annotation.dart';

part 'focus_record.g.dart';

/// 专注会话状态枚举
enum FocusSessionStatus {
  @JsonValue(0)
  active,      // 进行中
  @JsonValue(1)
  completed,   // 正常完成
  @JsonValue(2)
  paused,      // 暂停中
  @JsonValue(3)
  interrupted, // 被中断
  @JsonValue(4)
  cancelled    // 取消
}

/// 专注模式类型枚举
enum FocusModeType {
  @JsonValue(0)
  pomodoro,    // 番茄钟
  @JsonValue(1)
  custom,      // 自定义时长
  @JsonValue(2)
  freeform     // 自由模式
}

/// 专注记录实体类
@JsonSerializable()
class FocusRecord {
  final int? id;
  final int? taskId;
  final String? taskTitle;
  final FocusModeType modeType;
  final int plannedMinutes;
  final int actualMinutes;
  final FocusSessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final int pausedDuration; // 暂停总时长（秒）
  final int interruptionCount;
  final String? notes;
  final Map<String, dynamic> metadata; // 额外数据，如环境信息等
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const FocusRecord({
    this.id,
    this.taskId,
    this.taskTitle,
    this.modeType = FocusModeType.pomodoro,
    required this.plannedMinutes,
    this.actualMinutes = 0,
    this.status = FocusSessionStatus.active,
    required this.startTime,
    this.endTime,
    this.pausedAt,
    this.pausedDuration = 0,
    this.interruptionCount = 0,
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });
  
  /// 从JSON创建FocusRecord实例
  factory FocusRecord.fromJson(Map<String, dynamic> json) => _$FocusRecordFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FocusRecordToJson(this);
  
  /// 从数据库Map创建FocusRecord实例
  factory FocusRecord.fromMap(Map<String, dynamic> map) {
    return FocusRecord(
      id: map['id'] as int?,
      taskId: map['task_id'] as int?,
      taskTitle: map['task_title'] as String?,
      modeType: FocusModeType.values[map['mode_type'] as int],
      plannedMinutes: map['planned_minutes'] as int,
      actualMinutes: map['actual_minutes'] as int,
      status: FocusSessionStatus.values[map['status'] as int],
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String) 
          : null,
      pausedAt: map['paused_at'] != null 
          ? DateTime.parse(map['paused_at'] as String) 
          : null,
      pausedDuration: map['paused_duration'] as int? ?? 0,
      interruptionCount: map['interruption_count'] as int? ?? 0,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }
  
  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'mode_type': modeType.index,
      'planned_minutes': plannedMinutes,
      'actual_minutes': actualMinutes,
      'status': status.index,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'paused_duration': pausedDuration,
      'interruption_count': interruptionCount,
      'notes': notes,
      'metadata': metadata.isNotEmpty ? metadata : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 从数据库Map创建FocusRecord实例（兼容数据库字段名）
  factory FocusRecord.fromDatabaseMap(Map<String, dynamic> map) {
    return FocusRecord(
      id: map['id'] as int?,
      taskId: map['taskId'] as int?,
      taskTitle: map['taskTitle'] as String?,
      modeType: FocusModeType.values[map['modeType'] as int? ?? 0],
      plannedMinutes: map['plannedMinutes'] as int,
      actualMinutes: map['actualMinutes'] as int? ?? 0,
      status: FocusSessionStatus.values[map['status'] as int? ?? 0],
      startTime: map['startTime'] != null 
          ? DateTime.parse(map['startTime'] as String)
          : DateTime.now(),
      endTime: map['endTime'] != null 
          ? DateTime.parse(map['endTime'] as String) 
          : null,
      pausedAt: map['pausedAt'] != null 
          ? DateTime.parse(map['pausedAt'] as String) 
          : null,
      pausedDuration: map['pausedDuration'] as int? ?? 0,
      interruptionCount: map['interruptionCount'] as int? ?? 0,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
    );
  }

  /// 转换为数据库Map（兼容数据库字段名）
  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'modeType': modeType.index,
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'status': status.index,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'pausedDuration': pausedDuration,
      'interruptionCount': interruptionCount,
      'notes': notes,
      'metadata': metadata.isNotEmpty ? metadata : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// 复制并修改专注记录
  FocusRecord copyWith({
    int? id,
    int? taskId,
    String? taskTitle,
    FocusModeType? modeType,
    int? plannedMinutes,
    int? actualMinutes,
    FocusSessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pausedAt,
    int? pausedDuration,
    int? interruptionCount,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FocusRecord(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      modeType: modeType ?? this.modeType,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// 开始专注会话
  FocusRecord start() {
    return copyWith(
      status: FocusSessionStatus.active,
      startTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 暂停专注会话
  FocusRecord pause() {
    return copyWith(
      status: FocusSessionStatus.paused,
      pausedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 恢复专注会话
  FocusRecord resume() {
    final now = DateTime.now();
    final additionalPausedTime = pausedAt != null 
        ? now.difference(pausedAt!).inSeconds 
        : 0;
    
    return copyWith(
      status: FocusSessionStatus.active,
      pausedAt: null,
      pausedDuration: pausedDuration + additionalPausedTime,
      updatedAt: now,
    );
  }
  
  /// 完成专注会话
  FocusRecord complete({String? notes}) {
    final now = DateTime.now();
    final totalMinutes = _calculateActualMinutes(now);
    
    return copyWith(
      status: FocusSessionStatus.completed,
      endTime: now,
      actualMinutes: totalMinutes,
      notes: notes ?? this.notes,
      updatedAt: now,
    );
  }
  
  /// 中断专注会话
  FocusRecord interrupt({String? notes}) {
    final now = DateTime.now();
    final totalMinutes = _calculateActualMinutes(now);
    
    return copyWith(
      status: FocusSessionStatus.interrupted,
      endTime: now,
      actualMinutes: totalMinutes,
      interruptionCount: interruptionCount + 1,
      notes: notes ?? this.notes,
      updatedAt: now,
    );
  }
  
  /// 取消专注会话
  FocusRecord cancel({String? notes}) {
    final now = DateTime.now();
    final totalMinutes = _calculateActualMinutes(now);
    
    return copyWith(
      status: FocusSessionStatus.cancelled,
      endTime: now,
      actualMinutes: totalMinutes,
      notes: notes ?? this.notes,
      updatedAt: now,
    );
  }
  
  /// 添加中断次数
  FocusRecord addInterruption() {
    return copyWith(
      interruptionCount: interruptionCount + 1,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 计算实际专注时长（分钟）
  int _calculateActualMinutes(DateTime endTime) {
    final totalSeconds = endTime.difference(startTime).inSeconds - pausedDuration;
    return (totalSeconds / 60).round();
  }
  
  /// 获取当前实际专注时长（分钟）
  int get currentActualMinutes {
    if (status == FocusSessionStatus.active) {
      final now = DateTime.now();
      final currentPausedDuration = pausedAt != null 
          ? pausedDuration + now.difference(pausedAt!).inSeconds
          : pausedDuration;
      final totalSeconds = now.difference(startTime).inSeconds - currentPausedDuration;
      return (totalSeconds / 60).round().clamp(0, double.infinity).toInt();
    }
    return actualMinutes;
  }
  
  /// 获取剩余时间（分钟）
  int get remainingMinutes {
    if (status != FocusSessionStatus.active) return 0;
    return (plannedMinutes - currentActualMinutes).clamp(0, double.infinity).toInt();
  }
  
  /// 获取完成进度（0.0 - 1.0）
  double get progressPercentage {
    if (plannedMinutes <= 0) return 0.0;
    return (currentActualMinutes / plannedMinutes).clamp(0.0, 1.0);
  }
  
  /// 检查是否已完成计划时长
  bool get isPlannedTimeReached {
    return currentActualMinutes >= plannedMinutes;
  }
  
  /// 检查是否正在进行中
  bool get isActive {
    return status == FocusSessionStatus.active;
  }
  
  /// 检查是否已暂停
  bool get isPaused {
    return status == FocusSessionStatus.paused;
  }
  
  /// 检查是否已结束（完成、中断或取消）
  bool get isFinished {
    return status == FocusSessionStatus.completed ||
           status == FocusSessionStatus.interrupted ||
           status == FocusSessionStatus.cancelled;
  }
  
  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case FocusSessionStatus.active:
        return '进行中';
      case FocusSessionStatus.completed:
        return '已完成';
      case FocusSessionStatus.paused:
        return '已暂停';
      case FocusSessionStatus.interrupted:
        return '被中断';
      case FocusSessionStatus.cancelled:
        return '已取消';
    }
  }
  
  /// 获取模式类型显示文本
  String get modeTypeText {
    switch (modeType) {
      case FocusModeType.pomodoro:
        return '番茄钟';
      case FocusModeType.custom:
        return '自定义';
      case FocusModeType.freeform:
        return '自由模式';
    }
  }
  
  /// 获取专注效率（实际时长/计划时长）
  double get efficiency {
    if (plannedMinutes <= 0) return 0.0;
    return (actualMinutes / plannedMinutes).clamp(0.0, double.infinity);
  }
  
  /// 获取专注质量评分（基于中断次数和完成度）
  double get qualityScore {
    if (!isFinished) return 0.0;
    
    double baseScore = efficiency.clamp(0.0, 1.0);
    double interruptionPenalty = interruptionCount * 0.1;
    
    return (baseScore - interruptionPenalty).clamp(0.0, 1.0);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusRecord && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'FocusRecord(id: $id, taskId: $taskId, status: $status, actualMinutes: $actualMinutes)';
  }
}

/// 专注记录扩展方法
extension FocusRecordExtensions on List<FocusRecord> {
  /// 按开始时间排序
  List<FocusRecord> sortByStartTime({bool ascending = false}) {
    final sorted = List<FocusRecord>.from(this);
    sorted.sort((a, b) => ascending 
        ? a.startTime.compareTo(b.startTime)
        : b.startTime.compareTo(a.startTime));
    return sorted;
  }
  
  /// 筛选已完成的记录
  List<FocusRecord> get completed {
    return where((record) => record.status == FocusSessionStatus.completed).toList();
  }
  
  /// 筛选特定任务的记录
  List<FocusRecord> filterByTask(int taskId) {
    return where((record) => record.taskId == taskId).toList();
  }
  
  /// 筛选特定日期范围的记录
  List<FocusRecord> filterByDateRange(DateTime start, DateTime end) {
    return where((record) => 
        record.startTime.isAfter(start) && record.startTime.isBefore(end)
    ).toList();
  }
  
  /// 筛选今天的记录
  List<FocusRecord> get today {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return filterByDateRange(startOfDay, endOfDay);
  }
  
  /// 筛选本周的记录
  List<FocusRecord> get thisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    return filterByDateRange(startOfWeekDay, endOfWeek);
  }
  
  /// 计算总专注时长（分钟）
  int get totalFocusMinutes {
    return fold(0, (sum, record) => sum + record.actualMinutes);
  }
  
  /// 计算平均专注时长（分钟）
  double get averageFocusMinutes {
    if (isEmpty) return 0.0;
    return totalFocusMinutes / length;
  }
  
  /// 计算总中断次数
  int get totalInterruptions {
    return fold(0, (sum, record) => sum + record.interruptionCount);
  }
  
  /// 计算平均专注质量评分
  double get averageQualityScore {
    if (isEmpty) return 0.0;
    final completedRecords = completed;
    if (completedRecords.isEmpty) return 0.0;
    
    final totalScore = completedRecords.fold(0.0, (sum, record) => sum + record.qualityScore);
    return totalScore / completedRecords.length;
  }
  
  /// 获取最长专注记录
  FocusRecord? get longestSession {
    if (isEmpty) return null;
    return reduce((a, b) => a.actualMinutes > b.actualMinutes ? a : b);
  }
  
  /// 按模式类型分组
  Map<FocusModeType, List<FocusRecord>> groupByModeType() {
    final Map<FocusModeType, List<FocusRecord>> grouped = {};
    for (final record in this) {
      grouped.putIfAbsent(record.modeType, () => []).add(record);
    }
    return grouped;
  }
}