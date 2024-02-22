// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TestJson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestJson _$TestJsonFromJson(Map<String, dynamic> json) => TestJson(
      json['name'] as String,
      json['level'] as int,
      json['visible'] as bool,
      json['checked'] as bool,
      subNodes: (json['subNodes'] as List<dynamic>?)
          ?.map((e) => TestJson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TestJsonToJson(TestJson instance) => <String, dynamic>{
      'name': instance.name,
      'level': instance.level,
      'visible': instance.visible,
      'checked': instance.checked,
      'subNodes': instance.subNodes?.map((e) => e.toJson()).toList(),
    };
