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
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? category;
  final List<String> tags;
  final bool isArchived;
  final int sortOrder;
  final double progress; // 添加 progress 字段
  
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
    this.completedAt,
    this.dueDate,
    this.category,
    this.tags = const [],
    this.isArchived = false,
    this.sortOrder = 0,
    this.progress = 0.0, // 初始化 progress
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
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String) 
          : null,
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date'] as String) 
          : null,
      category: map['category'] as String?,
      tags: (map['tags'] as String? ?? '').split(',').where((tag) => tag.isNotEmpty).toList(),
      isArchived: (map['is_archived'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// 从数据库Map创建Task实例（兼容数据库字段名）
  factory Task.fromDatabaseMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.values[map['priority'] as int? ?? 1],
      status: _parseStatus(map['status']),
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 25,
      actualMinutes: map['actualMinutes'] as int? ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt'] as String) 
          : null,
      dueDate: map['dueDate'] != null 
          ? DateTime.parse(map['dueDate'] as String) 
          : null,
      category: map['category'] as String?,
      tags: (map['tags'] as String? ?? '').split(',').where((tag) => tag.isNotEmpty).toList(),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
      progress: (map['progress'] as num? ?? 0.0).toDouble(),
    );
  }

  /// 解析任务状态
  static TaskStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'todo':
        case 'pending':
          return TaskStatus.pending;
        case 'doing':
        case 'inProgress':
          return TaskStatus.inProgress;
        case 'done':
        case 'completed':
          return TaskStatus.completed;
        case 'paused':
        case 'cancelled':
          return TaskStatus.cancelled;
        default:
          return TaskStatus.pending;
      }
    } else if (status is int) {
      if (status >= 0 && status < TaskStatus.values.length) {
        return TaskStatus.values[status];
      }
    }
    return TaskStatus.pending;
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
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'category': category,
      'tags': tags.join(','),
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// 转换为数据库Map（兼容数据库字段名）
  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': _statusToString(status),
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'tags': tags.join(','),
      'isArchived': isArchived ? 1 : 0,
      'sortOrder': sortOrder,
      'progress': progress,
    };
  }

  /// 将状态转换为字符串
  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'todo';
      case TaskStatus.inProgress:
        return 'doing';
      case TaskStatus.completed:
        return 'done';
      case TaskStatus.cancelled:
        return 'paused';
    }
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
    DateTime? completedAt,
    DateTime? dueDate,
    String? category,
    List<String>? tags,
    bool? isArchived,
    int? sortOrder,
    double? progress,
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
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      progress: progress ?? this.progress,
    );
  }
  
  /// 标记任务为完成
  Task markAsCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      progress: 1.0,
      updatedAt: DateTime.now(),
      completedAt: DateTime.now(),
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
  
  /// 按完成时间排序
  List<Task> sortByCompletedAt({bool ascending = false}) {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) return 0;
      if (a.completedAt == null) return 1;
      if (b.completedAt == null) return -1;
      return ascending 
          ? a.completedAt!.compareTo(b.completedAt!)
          : b.completedAt!.compareTo(a.completedAt!);
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
             task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}