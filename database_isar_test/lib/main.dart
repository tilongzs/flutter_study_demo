import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Isar _isar; // Isar 实例
  int   _currentEmailID = 0;

  // 打开数据库
  void openDB() async{
    final dir = "D:/";
    _isar = await Isar.open(
      [EmailSchema],
      directory: dir,
      name: 'testdb'
    );

    if(_isar == null){
      print('数据库打开失败');
    }else{
      print('数据库打开成功');
    }
  }

  // 删除数据库
  Future<void> deleteDB() async{
    print('删除数据库');
    _isar.close(deleteFromDisk: true);
  }

  // 增
  Future<int> add() async{
    // 创建一行数据
    final newEmail = Email();
    newEmail.title = '邮件标题';
    newEmail.dateTime = DateTime.now();
    newEmail.attachmentSize = Random().nextInt(3);
    final recipient = Recepient();
    recipient.name = 'mengmei';
    recipient.address = 'mm@mengmei.moe';
    newEmail.recipient = recipient;

    // 存入数据库
    await _isar.writeTxn(() async { // 写操作的代码必须放置在isar.writeTxn()中
      _currentEmailID = await _isar.emails.put(newEmail);
      print('新增一行数据 id:${newEmail.id} attachmentSize:${newEmail.attachmentSize}');
    });

    return _currentEmailID;
  }

  // 删
  Future<bool> delete() async{
    if(_currentEmailID != 0){
      var ret = false;
      await _isar.writeTxn(() async { // 写操作的代码必须放置在isar.writeTxn()中
        ret = await _isar.emails.delete(_currentEmailID);
        print('删除一行数据 id:$_currentEmailID ${ret}');
      });

      return ret;
    }

    print('先增加数据');
    return true;
  }

  // 清空表
  Future<void> clear() async{
    await _isar.writeTxn(() async { // 写操作的代码必须放置在isar.writeTxn()中
      _isar.emails.clear();
      print('清空表');
    });
  }

  // 删除所有表
  Future<void> deleteAllData() async{
    await _isar.writeTxn(() async { // 写操作的代码必须放置在isar.writeTxn()中
      _isar.clear();
      print('删除所有表');
    });
  }

  // 改
  Future<void> modify() async{
    // 使用唯一id查找数据
    final existingEmail = await _isar.emails.get(_currentEmailID);
    if(existingEmail == null){
      print('没有找到数据 id:$_currentEmailID');
    }else{
      // 修改数据
      existingEmail.title = '修改后的数据';
      existingEmail.dateTime = DateTime.now();
      await _isar.writeTxn(() async { // 写操作的代码必须放置在isar.writeTxn()中
        _currentEmailID = await _isar.emails.put(existingEmail);
        print('修改一行数据 id:$_currentEmailID title.title=${existingEmail.title} datetime:${existingEmail.dateTime}');
      });
    }
  }

  // 查
  void find() async{
    if(_currentEmailID != 0){
      // 使用唯一id查找数据
      final existingEmail = await _isar.emails.get(_currentEmailID);
      if(existingEmail == null){
        print('没有找到数据 id:$_currentEmailID');
      }else{
        print('找到数据 id:$_currentEmailID title:${existingEmail.title} datetime:${existingEmail.dateTime}');
      }

      return;
    }

    print('先增加数据');
  }

  // 索引查询where()
  void whereAttachmentSize() async{
    final result = await _isar.emails.where().attachmentSizeEqualTo(2).findAll();
    print('查找附件大小为2的所有数据 共${result.length}个');
    result.forEach((e) {
      print('查找到数据 id:${e.id} datetime:${e.dateTime}');
    });
  }

  // 非索引查询filter()
  void filterDatetime() async{
    final result = await _isar.emails.filter().dateTimeLessThan(DateTime.now()).findAll();
    print('查找比当前时间小的所有数据 共${result.length}个');
    result.forEach((e) {
      print('查找到数据 id:${e.id} datetime:${e.dateTime}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 150,
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 10,
            spacing:5,
            children: <Widget>[
              ElevatedButton(onPressed: openDB, child: Text('打开数据库')),
              ElevatedButton(onPressed: deleteDB, child: Text('删除数据库')),
              ElevatedButton(onPressed: add, child: Text('增')),
              ElevatedButton(onPressed: delete, child: Text('删')),
              ElevatedButton(onPressed: clear, child: Text('清空表')),
              ElevatedButton(onPressed: deleteAllData, child: Text('删除所有表')),
              ElevatedButton(onPressed: modify, child: Text('改')),
              ElevatedButton(onPressed: find, child: Text('查')),
              ElevatedButton(onPressed: whereAttachmentSize, child: Text('索引where()')),
              ElevatedButton(onPressed: filterDatetime, child: Text('非索引filter()')),
            ],
          ),
        ),
      ),
    );
  }
}
