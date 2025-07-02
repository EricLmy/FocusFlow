// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FocusRecord _$FocusRecordFromJson(Map<String, dynamic> json) => FocusRecord(
  id: (json['id'] as num?)?.toInt(),
  taskId: (json['taskId'] as num?)?.toInt(),
  taskTitle: json['taskTitle'] as String?,
  modeType:
      $enumDecodeNullable(_$FocusModeTypeEnumMap, json['modeType']) ??
      FocusModeType.pomodoro,
  plannedMinutes: (json['plannedMinutes'] as num).toInt(),
  actualMinutes: (json['actualMinutes'] as num?)?.toInt() ?? 0,
  status:
      $enumDecodeNullable(_$FocusSessionStatusEnumMap, json['status']) ??
      FocusSessionStatus.active,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  pausedAt: json['pausedAt'] == null
      ? null
      : DateTime.parse(json['pausedAt'] as String),
  pausedDuration: (json['pausedDuration'] as num?)?.toInt() ?? 0,
  interruptionCount: (json['interruptionCount'] as num?)?.toInt() ?? 0,
  notes: json['notes'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FocusRecordToJson(FocusRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'taskTitle': instance.taskTitle,
      'modeType': _$FocusModeTypeEnumMap[instance.modeType]!,
      'plannedMinutes': instance.plannedMinutes,
      'actualMinutes': instance.actualMinutes,
      'status': _$FocusSessionStatusEnumMap[instance.status]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'pausedAt': instance.pausedAt?.toIso8601String(),
      'pausedDuration': instance.pausedDuration,
      'interruptionCount': instance.interruptionCount,
      'notes': instance.notes,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$FocusModeTypeEnumMap = {
  FocusModeType.pomodoro: 0,
  FocusModeType.custom: 1,
  FocusModeType.freeform: 2,
};

const _$FocusSessionStatusEnumMap = {
  FocusSessionStatus.active: 0,
  FocusSessionStatus.completed: 1,
  FocusSessionStatus.paused: 2,
  FocusSessionStatus.interrupted: 3,
  FocusSessionStatus.cancelled: 4,
};
