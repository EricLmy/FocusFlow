// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  priority:
      $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
      TaskPriority.medium,
  status:
      $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
      TaskStatus.pending,
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 25,
  actualMinutes: (json['actualMinutes'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  category: json['category'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'estimatedMinutes': instance.estimatedMinutes,
  'actualMinutes': instance.actualMinutes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'dueDate': instance.dueDate?.toIso8601String(),
  'tags': instance.tags,
  'category': instance.category,
  'isArchived': instance.isArchived,
  'sortOrder': instance.sortOrder,
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 1,
  TaskPriority.medium: 2,
  TaskPriority.high: 3,
  TaskPriority.urgent: 4,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 0,
  TaskStatus.inProgress: 1,
  TaskStatus.completed: 2,
  TaskStatus.cancelled: 3,
};
