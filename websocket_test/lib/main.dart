import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'websocket test'),
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
  final List<String> _recvMsg = []; // 接收到的消息

  late WebSocketChannel _webSocketChannel;
  bool _isConnected = false;

  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _serverTxtController = TextEditingController(); //  连接服务器文本控制器

  // 连接到Server
  void onBtnConnectToServer() async {
    final uri = Uri.parse(_serverTxtController.text);
    _webSocketChannel = WebSocketChannel.connect(uri);

    // 处理连接成功状态
    _webSocketChannel.ready.then((value) => printLog("连接服务端成功"));

    // 处理接收数据、连接断开
    _webSocketChannel.stream.listen(
        // "dynamic" because dataFromServer can be String or List<int>
        (dynamic dataFromServer) {
          if (dataFromServer is List<int>) {
            printLog("收到二进制数据：共${(dataFromServer as List<int>).length}字节");
          } else { // dataFromServer is String
            printLog("收到字符串数据：${dataFromServer}");
          } // dataFromServer is String
        }, //  dataFromServer

        onDone: (){
          // https://api.dart.dev/stable/2.17.3/dart-io/WebSocket/closeReason.html
          // If there is no close reason available, "webSocketChannel.closeReason" will be null
          printLog('onDone: Will close WebSocket: ${_webSocketChannel.closeReason}');
          _webSocketChannel.sink.close();
          _isConnected = false;
          setState(() {});
        },

        onError: (err){
          // https://api.dart.dev/stable/2.17.3/dart-io/WebSocket/closeReason.html
          // If there is no close reason available, "webSocketChannel.closeReason" will be null
          printLog('onError${err}: Will close WebSocket: ${_webSocketChannel.closeReason}');
          _webSocketChannel.sink.close();
          _isConnected = false;
          setState(() {});
        },

        // https://api.dart.dev/stable/2.17.3/dart-async/Stream/listen.html
        // If cancelOnError is true, the subscription is automatically canceled
        // when the first error event is delivered.
        // The default is false.
        cancelOnError: false,
    );
  }

  // 手动断开连接
  void onBtnDisconnectToServer() async{
    _webSocketChannel.sink.close(status.goingAway);
    printLog('手动断开连接');

    setState(() {});
  }

  // 发送消息
  void onBtnSendMsg() async {
    if (_sendMsgController.text.isNotEmpty) {
      _webSocketChannel.sink.add(_sendMsgController.text);
      printLog('发送数据${_sendMsgController.text.length}字节');

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  @override
  void initState() {
    _serverTxtController.text = 'ws://127.0.0.1:23300/websocket';

    super.initState();
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
            recvMsgListview(), // 接收消息列表框
            IPSettingRect(), // 设置IP、端口区域
            sendMsgRect(), // 发送消息区域
          ],
        ),
      ),
    );
  }

  // 接收消息列表框
  Widget recvMsgListview() {
    return Container(
      margin: EdgeInsets.all(10),
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
        ),
        color: Colors.black12,
      ),
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Text(_recvMsg[index]);
        },
        itemCount: _recvMsg.length,
      ),
    );
  }
  /*****************************************************************************/

  Widget IPSettingRect() {
    Function createConnectButton = () {
      return ElevatedButton(onPressed: onBtnConnectToServer, child: Text('连接'));
    };

    Function createDisconnectButton = () {
      return ElevatedButton(
          onPressed: onBtnDisconnectToServer,
          child: Text('断开连接'));
    };

    return Container(
      margin: EdgeInsets.all(10),
      child: Wrap(
        direction: Axis.vertical,
        spacing: 10,
        children: [
          // 服务端地址
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('服务端地址：'),
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      maxLines: 1,
                      controller: _serverTxtController,
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 连接按钮
          _isConnected
              ? createDisconnectButton()
              : createConnectButton(),
        ],
      ),
    );
  }
  /********************************************************************/

  Widget sendMsgRect() {
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            // 输入区域
            height: 40,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
              ),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: _sendMsgController,
                autofocus: true,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(onPressed: onBtnSendMsg, child: Text('发送消息')),
            ],
          ),
        ],
      ),
    );
  }

  // 打印日志
  void printLog(String log) {
    String finalLog = DateTime.now().toString() +" " + log;
    print(finalLog);
    _recvMsg.add(finalLog);
    setState(() {});
  }
}
