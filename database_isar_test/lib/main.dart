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

  // 增
  Future<int> add() async{
    // 创建一行数据
    final newEmail = Email();
    newEmail.title = '邮件标题';
    final recipient = Recepient();
    recipient.name = 'mengmei';
    recipient.address = 'mm@mengmei.moe';
    newEmail.recipient = recipient;

    // 存入数据库
    await _isar.writeTxn(() async {
      _currentEmailID = await _isar.emails.put(newEmail);
    });

    return _currentEmailID;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: openDB, child: Text('打开数据库')),
            ElevatedButton(onPressed: add, child: Text('增'))
          ],
        ),
      ),
    );
  }
}
