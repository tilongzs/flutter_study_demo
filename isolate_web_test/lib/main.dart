import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';

import 'function_name.dart';
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
              child: ElevatedButton(
                  onPressed: () async{
                    _count = await jsCountNum(1000000000);
                    setState(() { });
                  },
                  child: Text(_count.toString())),
            )
          ],
        ),
      ),
    );
  }

  static Future<int> jsCountNum(int num) async{
    final isolateManager = IsolateManager.create(
        functionName,
        workerName: 'function_name'
    );

    await isolateManager.start();

    // 执行多线程函数
    int count = int.parse(await isolateManager.sendMessage(num));
    isolateManager.stop();
    return count;
  }
}