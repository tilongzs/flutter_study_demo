import 'package:json_annotation/json_annotation.dart';

// 稍后以 json_serializable 的方式创建模型类
// 执行dart run build_runner watch --delete-conflicting-outputs
part 'TestJson.g.dart';

@JsonSerializable(explicitToJson: true)
class TestJson {
  TestJson(this.name, this.level, this.visible, this.checked, {this.subNodes});

  String  name;
  int     level;
  bool    visible;
  bool    checked;
  List<TestJson>?  subNodes;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$TestJsonFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory TestJson.fromJson(Map<String, dynamic> json) => _$TestJsonFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$TestJsonToJson`.
  Map<String, dynamic> toJson() => _$TestJsonToJson(this);
}