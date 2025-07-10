import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'draft.g.dart';

/// 任务草稿实体类
/// 用于保存用户未完成的任务编辑内容
@JsonSerializable()
class Draft {
  final int? id;
  final Map<String, dynamic> taskData;
  final DateTime saveTime;
  
  const Draft({
    this.id,
    required this.taskData,
    required this.saveTime,
  });
  
  /// 从JSON创建Draft实例
  factory Draft.fromJson(Map<String, dynamic> json) => _$DraftFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$DraftToJson(this);
  
  /// 从数据库Map创建Draft实例
  factory Draft.fromMap(Map<String, dynamic> map) {
    return Draft(
      id: map['id'] as int?,
      taskData: jsonDecode(map['task_data'] as String) as Map<String, dynamic>,
      saveTime: DateTime.parse(map['save_time'] as String),
    );
  }
  
  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_data': jsonEncode(taskData),
      'save_time': saveTime.toIso8601String(),
    };
  }
  
  /// 复制并修改草稿
  Draft copyWith({
    int? id,
    Map<String, dynamic>? taskData,
    DateTime? saveTime,
  }) {
    return Draft(
      id: id ?? this.id,
      taskData: taskData ?? this.taskData,
      saveTime: saveTime ?? this.saveTime,
    );
  }
  
  /// 更新任务数据
  Draft updateTaskData(Map<String, dynamic> newTaskData) {
    return copyWith(
      taskData: newTaskData,
      saveTime: DateTime.now(),
    );
  }
  
  /// 获取任务标题（如果存在）
  String? get taskTitle {
    return taskData['title'] as String?;
  }
  
  /// 获取任务描述（如果存在）
  String? get taskDescription {
    return taskData['description'] as String?;
  }
  
  /// 检查草稿是否为空
  bool get isEmpty {
    return taskData.isEmpty || 
           (taskData['title'] as String?)?.trim().isEmpty == true;
  }
  
  /// 检查草稿是否有效（包含必要字段）
  bool get isValid {
    final title = taskData['title'] as String?;
    return title != null && title.trim().isNotEmpty;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Draft && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'Draft(id: $id, taskTitle: $taskTitle, saveTime: $saveTime)';
  }
}

/// 草稿扩展方法
extension DraftExtensions on List<Draft> {
  /// 按保存时间排序
  List<Draft> sortBySaveTime({bool ascending = false}) {
    final sorted = List<Draft>.from(this);
    sorted.sort((a, b) => ascending 
        ? a.saveTime.compareTo(b.saveTime)
        : b.saveTime.compareTo(a.saveTime));
    return sorted;
  }
  
  /// 筛选有效的草稿
  List<Draft> get valid {
    return where((draft) => draft.isValid).toList();
  }
  
  /// 筛选空的草稿
  List<Draft> get empty {
    return where((draft) => draft.isEmpty).toList();
  }
  
  /// 获取最新的草稿
  Draft? get latest {
    if (isEmpty) return null;
    return sortBySaveTime().first;
  }
  
  /// 清理过期的草稿（超过指定天数）
  List<Draft> cleanupOldDrafts({int daysToKeep = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return where((draft) => draft.saveTime.isAfter(cutoffDate)).toList();
  }
}