import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

/// 任务优先级枚举
enum TaskPriority {
  @JsonValue(1)
  low,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  high,
  @JsonValue(4)
  urgent
}

/// 任务状态枚举
enum TaskStatus {
  @JsonValue(0)
  pending,
  @JsonValue(1)
  inProgress,
  @JsonValue(2)
  completed,
  @JsonValue(3)
  cancelled
}

/// 任务实体类
@JsonSerializable()
class Task {
  final int? id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final int estimatedMinutes;
  final int actualMinutes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;
  final List<String> tags;
  final String? category;
  final bool isArchived;
  final int sortOrder;
  
  const Task({
    this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.estimatedMinutes = 25,
    this.actualMinutes = 0,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.tags = const [],
    this.category,
    this.isArchived = false,
    this.sortOrder = 0,
  });
  
  /// 从JSON创建Task实例
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => _$TaskToJson(this);
  
  /// 从数据库Map创建Task实例
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.values[map['priority'] as int],
      status: TaskStatus.values[map['status'] as int],
      estimatedMinutes: map['estimated_minutes'] as int,
      actualMinutes: map['actual_minutes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date'] as String) 
          : null,
      tags: (map['tags'] as String? ?? '').split(',').where((tag) => tag.isNotEmpty).toList(),
      category: map['category'] as String?,
      isArchived: (map['is_archived'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
  
  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.index,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'tags': tags.join(','),
      'category': category,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
  
  /// 复制并修改任务
  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    int? estimatedMinutes,
    int? actualMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    List<String>? tags,
    String? category,
    bool? isArchived,
    int? sortOrder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
  
  /// 标记任务为完成
  Task markAsCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 标记任务为进行中
  Task markAsInProgress() {
    return copyWith(
      status: TaskStatus.inProgress,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 添加实际用时
  Task addActualMinutes(int minutes) {
    return copyWith(
      actualMinutes: actualMinutes + minutes,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 归档任务
  Task archive() {
    return copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 取消归档
  Task unarchive() {
    return copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 检查任务是否逾期
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }
  
  /// 检查任务是否即将到期（24小时内）
  bool get isDueSoon {
    if (dueDate == null || status == TaskStatus.completed) {
      return false;
    }
    final now = DateTime.now();
    final timeDiff = dueDate!.difference(now);
    return timeDiff.inHours <= 24 && timeDiff.inHours > 0;
  }
  
  /// 获取优先级显示文本
  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }
  
  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return '待开始';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }
  
  /// 获取完成进度（基于实际用时和预估用时）
  double get progressPercentage {
    if (estimatedMinutes <= 0) return 0.0;
    return (actualMinutes / estimatedMinutes).clamp(0.0, 1.0);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority)';
  }
}

/// 任务扩展方法
extension TaskExtensions on List<Task> {
  /// 按优先级排序
  List<Task> sortByPriority() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return sorted;
  }
  
  /// 按创建时间排序
  List<Task> sortByCreatedAt({bool ascending = false}) {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => ascending 
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
  
  /// 按截止时间排序
  List<Task> sortByDueDate() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }
  
  /// 按自定义排序
  List<Task> sortByOrder() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }
  
  /// 筛选未完成的任务
  List<Task> get pending {
    return where((task) => task.status != TaskStatus.completed && !task.isArchived).toList();
  }
  
  /// 筛选已完成的任务
  List<Task> get completed {
    return where((task) => task.status == TaskStatus.completed).toList();
  }
  
  /// 筛选逾期任务
  List<Task> get overdue {
    return where((task) => task.isOverdue).toList();
  }
  
  /// 筛选即将到期的任务
  List<Task> get dueSoon {
    return where((task) => task.isDueSoon).toList();
  }
  
  /// 按分类筛选
  List<Task> filterByCategory(String? category) {
    if (category == null) return this;
    return where((task) => task.category == category).toList();
  }
  
  /// 按标签筛选
  List<Task> filterByTag(String tag) {
    return where((task) => task.tags.contains(tag)).toList();
  }
  
  /// 搜索任务
  List<Task> search(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
             (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
             task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
             (task.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}