import 'package:isar/isar.dart';
part 'table.g.dart';

// 类名即表名
@collection
class Email {
  Id id = Isar.autoIncrement; // 必须字段。
  String? title;
  // 模拟类嵌套
  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;
  String? address;
}
