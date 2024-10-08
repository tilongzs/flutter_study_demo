import 'package:isar/isar.dart';
// 稍后会通过代码生成器（build_runner）来生成该文件
// Terminal执行flutter pub run build_runner build或者flutter pub run build_runner watch
part 'table.g.dart';

// 类名即表名
@collection
class Email {
  Id id = Isar.autoIncrement; // 唯一自增ID；必须字段。
  String? title;
  DateTime? dateTime;

  @Index()
  int? attachmentSize; // 索引

  // 模拟类嵌套
  Recepient? recipient;
}

// 被嵌套的类
@embedded
class Recepient {
  String? name;
  String? address;
}
