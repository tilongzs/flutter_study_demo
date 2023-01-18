import 'package:flutter/material.dart';
import 'package:websocket_universal/websocket_universal.dart';
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

  late IWebSocketHandler<List<int>, List<int>> bytesSocketHandler;
  bool _isConnected = false;

  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _serverTxtController = TextEditingController(); //  连接服务器文本控制器

  // 连接到Server
  void onBtnConnectToServer() async {
    String uri = _serverTxtController.text;

    const connectionOptions = SocketConnectionOptions(
        pingIntervalMs: 3000, // send Ping message every 3000 ms
        timeoutConnectionMs: 4000, // connection fail timeout after 4000 ms
        /// see ping/pong messages in [logEventStream] stream
        skipPingMessages: false,

        /// Set this attribute to `true` if do not need any ping/pong
        /// messages and ping measurement. Default is `false`
        pingRestrictionForce: true,
        failedReconnectionAttemptsLimit: 0
    );

    /// Example with simple text messages exchanges with server
    /// (not recommended for applications)
    /// [<String, String>] generic types mean that we receive [String] messages
    /// after deserialization and send [String] messages to server.
    final IMessageProcessor<List<int>, List<int>> bytesSocketProcessor  = SocketSimpleBytesProcessor();
    bytesSocketHandler = IWebSocketHandler<List<int>, List<int>>.createClient(
      uri,
      bytesSocketProcessor,
      connectionOptions: connectionOptions,
    );

    // Listening to webSocket status changes
    bytesSocketHandler.socketHandlerStateStream.listen((stateEvent) {
      _isConnected = (stateEvent.status == SocketStatus.connected);
      // ignore: avoid_print
      printLog('连接状态改变： ${stateEvent.status}');
    });

    // Listening to server responses:
    bytesSocketHandler.incomingMessagesStream.listen((inMsg) {
      // ignore: avoid_print
      printLog('收到服务端发来的: "${inMsg.length}字节数据" '
          '[ping: ${bytesSocketHandler.pingDelayMs}]');
    });

    // 开始连接
    _isConnected = await bytesSocketHandler.connect();
    if (!_isConnected) {
      printLog('连接 [$uri] 失败!');
      return;
    }
  }

  // 断开连接
  void onBtnDisconnectToServer() async{
    await bytesSocketHandler.disconnect('手动断开连接');
    // Disposing webSocket:
    bytesSocketHandler.close();
    _isConnected = false;
    printLog('手动断开连接');

    setState(() {});
  }

  // 发送消息
  void onBtnSendMsg() async {
    if (_sendMsgController.text.isNotEmpty) {
      var sendData = utf8.encode(_sendMsgController.text);
      bytesSocketHandler.sendMessage(sendData);

      printLog('发送数据${sendData.length}字节');

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
