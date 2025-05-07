import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
// 参考：https://mp.weixin.qq.com/s/ZkhAh-w0BS1J1yY_FnfvQA

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
      home: const MyHomePage(title: '调试-模板代码'),
    );
  }
}

class Singleton {
  static Singleton? _instance;
  static final _lock = Lock();

  Singleton._();

  static Singleton get instance {
    if (_instance == null) {
      _lock.synchronized(() {
        _instance ??= Singleton._();
        print('单例模式的类第一次初始化');
      });
    }
    return _instance!;
  }

  int _a = 10;

  void functionA(){
    _a++;
    print('functionA() _a:$_a');
  }
}

/* 多线程环境下，如果多个线程同时访问 instance 方法，可能会创建多个实例
class Singleton {
  // 1. 私有构造函数，防止外部实例化
  Singleton._();

  // 2. 静态私有成员变量，未初始化
  static Singleton? _instance;

  // 3. 公共静态方法，提供全局访问点
  static Singleton get instance {
    // 如果实例为空，则创建一个新的实例
    _instance ??= Singleton._();
    return _instance!;
  }
}
*/

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

    printLog('initState()');
  }

  @override
  void dispose(){
    _msgController.dispose();

    super.dispose();
  }

  void useSingletonClass() async{
    var obj = Singleton.instance;
    obj.functionA();
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
            ElevatedButton(onPressed: useSingletonClass, child: Text('使用单例模式的类'))
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
