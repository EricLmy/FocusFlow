// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportRecord _$ExportRecordFromJson(Map<String, dynamic> json) => ExportRecord(
  id: (json['id'] as num?)?.toInt(),
  exportType: $enumDecode(_$ExportTypeEnumMap, json['exportType']),
  exportScope: $enumDecode(_$ExportScopeEnumMap, json['exportScope']),
  exportTime: DateTime.parse(json['exportTime'] as String),
  filePath: json['filePath'] as String,
  status:
      $enumDecodeNullable(_$ExportStatusEnumMap, json['status']) ??
      ExportStatus.success,
  errorMsg: json['errorMsg'] as String?,
);

Map<String, dynamic> _$ExportRecordToJson(ExportRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exportType': _$ExportTypeEnumMap[instance.exportType]!,
      'exportScope': _$ExportScopeEnumMap[instance.exportScope]!,
      'exportTime': instance.exportTime.toIso8601String(),
      'filePath': instance.filePath,
      'status': _$ExportStatusEnumMap[instance.status]!,
      'errorMsg': instance.errorMsg,
    };

const _$ExportTypeEnumMap = {ExportType.csv: 'csv', ExportType.xlsx: 'xlsx'};

const _$ExportScopeEnumMap = {
  ExportScope.day: 'day',
  ExportScope.week: 'week',
  ExportScope.month: 'month',
  ExportScope.all: 'all',
};

const _$ExportStatusEnumMap = {
  ExportStatus.success: 'success',
  ExportStatus.failed: 'failed',
};
