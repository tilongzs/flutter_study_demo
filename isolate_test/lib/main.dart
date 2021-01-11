import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp>{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title :'App',
      initialRoute: '/',
      routes: {
        '/':(context)=>HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>{
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(),
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: RaisedButton(
                  color: Colors.amberAccent,
                  onPressed: () async{
                    _count = await compute(isolateCountEvent, 1000000000);
                   //  _count = await isolateCountEvent2(1000000000);
                    setState(() { });
                  },
                  child: Text(_count.toString())),
            )
          ],
        ),
      ),
    );
  }

  static Future<int> isolateCountEvent(int num) async {
    int count = 0;
    while (num > 0) {
      if (num % 2 == 0) {
        count++;
      }
      num--;
    }
    return count;
  }

  static Future<dynamic> isolateCountEvent2(int num) async {
    // 获取处理函数的SendPort
    final receivePort = ReceivePort();
    await Isolate.spawn(isolateCountProc, receivePort.sendPort);
    final procPort = await receivePort.first; //  获取到处理函数的SendPort，receivePort不能继续使用

    // 向处理函数发送处理请求
    final answer = ReceivePort();
    procPort.send([answer.sendPort, num]);
    return answer.first;
  }

  // 处理函数
  static void isolateCountProc(SendPort port) {
    var countFunc = (int num){
      int count = 0;
      while (num > 0) {
        if (num % 2 == 0) {
          count++;
        }
        num--;
      }
      return count;
    };

    final rPort = ReceivePort();
    rPort.listen((message) {
      final send = message[0] as SendPort;
      final n = message[1] as int;
      send.send(countFunc(n));
    });

    port.send(rPort.sendPort);
  }

}