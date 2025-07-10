// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Draft _$DraftFromJson(Map<String, dynamic> json) => Draft(
  id: (json['id'] as num?)?.toInt(),
  taskData: json['taskData'] as Map<String, dynamic>,
  saveTime: DateTime.parse(json['saveTime'] as String),
);

Map<String, dynamic> _$DraftToJson(Draft instance) => <String, dynamic>{
  'id': instance.id,
  'taskData': instance.taskData,
  'saveTime': instance.saveTime.toIso8601String(),
};
