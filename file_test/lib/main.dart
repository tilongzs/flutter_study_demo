import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  final TextEditingController _msgController = TextEditingController(); // 接收消息文本控制器
  final ScrollController      _msgScrollController = ScrollController();
  List<String>                _validPathList = [];
  String?                     _assetImagePath;

  @override
  void initState(){
    super.initState();

    printLog('initState()');
  }

  @override
  void dispose(){
    _msgController.dispose();
    _msgScrollController.dispose();

    super.dispose();
  }

  // 尝试获取所有路径
  void showAllPath() async {
    void showDirectoryInfo(Directory? directory){
      if(directory != null){
        printLog('--->' + directory.path);
        _validPathList.add(directory.path);
      }
    };

    void showDirectoryInfoList(List<Directory>? directoryList){
      if(directoryList != null){
        directoryList.map((e) => printLog(e.toString()));
      }
    };

    void onError(Object data, StackTrace stackTrace){
      printLog('onError->' + data.toString());
    }

    // Android iOS Linux macOS Windows通用路径
    printLog('getTemporaryDirectory:'); // 临时文件夹
    await getTemporaryDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getApplicationSupportDirectory:'); // 放置应用程序支持文件的文件夹，不向用户公开，不应将此文件夹用于存放用户数据文件。
    await getApplicationSupportDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getApplicationDocumentsDirectory:'); // 放置用户生成的数据的文件夹
    await getApplicationDocumentsDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getApplicationCacheDirectory:');
    await getApplicationCacheDirectory().then(showDirectoryInfo, onError: onError);

    // 其他路径
    printLog('getLibraryDirectory:');
    await getLibraryDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getDownloadsDirectory:');
    await getDownloadsDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getExternalStorageDirectory:');
    await getExternalStorageDirectory().then(showDirectoryInfo, onError: onError);

    printLog('getExternalStorageDirectories:');
    await getExternalStorageDirectories().then(showDirectoryInfoList, onError: onError);

    printLog('getExternalCacheDirectories:');
    await getExternalCacheDirectories().then(showDirectoryInfoList, onError: onError);
  }

  void tryRW(){
    _validPathList.add('U:/'); // 测试不存在的文件夹路径

    _validPathList.forEach((String directoryPath) async {
      Directory dir = Directory(directoryPath);
      dir.exists().then((dirExist) {
        // 故意不做判断dirExist，以便测试异常
        String filePath = path.join(directoryPath, 'test.txt');
        File file = File(filePath);
        file.create(recursive: true).then((file) { // 创建文件
          file.writeAsString('$filePath').then((file){ // 写入文件
            printLog('写入文件成功 $filePath');
            file.readAsString().then((value) { // 读取文件
              printLog('readFile:${value}');
              file.delete();// 删除文件
            });
          }, onError: (Object data, StackTrace stackTrace){
            printLog('writeAsString onError->' + data.toString());
          });
        }, onError: (Object data, StackTrace stackTrace){
          printLog('file.create onError->' + data.toString());
        });
      });
    });
  }
  
  void loadAssetImg(){
    setState(() {
      _assetImagePath = 'images/wind.JPG';
    });
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
            if(_assetImagePath != null) // 仅当手动加载图片时显示
              Image.asset(_assetImagePath!, width: 100, height: 100,),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(onPressed: showAllPath, child: const Text('尝试获取所有路径')),
                ElevatedButton(onPressed: tryRW, child: const Text('尝试读写')),
                ElevatedButton(onPressed: loadAssetImg, child: const Text('读取asset图片')),
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
