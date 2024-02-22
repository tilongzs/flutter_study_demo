import 'dart:convert';

import 'package:flutter/material.dart';
import 'TestJson.dart';

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
      home: const MyHomePage(title: 'JSON示例代码'),
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
  final TextEditingController _msgController = TextEditingController(); // 接收消息文本控制器
  final ScrollController      _msgScrollController = ScrollController();

  @override
  void initState(){
    super.initState();

    printLog('参考文文章https://flutter.cn/docs/data-and-backend/serialization/json');
  }

  @override
  void dispose(){
    _msgController.dispose();

    super.dispose();
  }

  void showJson(){
    TestJson testJson2 = TestJson('A2', 1, true, false);
    List<TestJson> testJsonList = [];
    testJsonList.add(testJson2);
    TestJson testJson = TestJson('A1', 0, true, true, subNodes: testJsonList);
    String testJsonString = jsonEncode(testJson.toJson()); // JSON序列化
    printLog(testJsonString);

    try{
      final parsedJson = jsonDecode(testJsonString); // JSON反序列化
      TestJson testCopy = TestJson.fromJson(parsedJson);
      printLog(testCopy.toString());
    }catch(e){
      printLog('JSON反序列化异常:$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            msgListview(),
            Wrap(children: [
              ElevatedButton(onPressed: showJson, child: Text('json示例'))
            ],)
          ],
        ),
      ),
    );
  }

  // 接收消息列表框
  Widget msgListview() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.black12,
      ),
      height: 300,
      child: TextField(
        readOnly: true,
        controller: _msgController,
        scrollController: _msgScrollController,
        expands: true, // 填充父窗口
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10)
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  // 打印日志
  void printLog(String log) {
    setState(() {
      log = '${DateTime.now()}\t$log';
      print(log);
      log += '\n';
      _msgController.text += log;

      if (_msgScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 30), () { // 延迟等待位置数据更新
          _msgScrollController.jumpTo(
            _msgScrollController.position.maxScrollExtent, //滚动到底部
          );
        });
      }
    });
  }
}
