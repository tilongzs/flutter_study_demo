import 'package:flutter/material.dart';

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

  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _serverTxtController = TextEditingController(); //  连接服务器文本控制器
  TextEditingController _portTxtController = TextEditingController(); //  连接服务器端口文本控制器

  // 连接到Server
  void onBtnConnectToServer() async {
    // var serverIP = _IPTxtController.text;
    // var serverPot = int.parse(_portTxtController.text);
    // try {
    //   _connectedSocket = await Socket.connect(serverIP, serverPot, timeout: Duration(milliseconds: 500));
    //   _connectedSocket.listen(onSocketData, onError: onSocketError, onDone: onSocketDone);
    //
    //   printLog('与服务端建立连接');
    //   setState(() {});
    // } catch (e) {
    //   printLog('连接socket出现异常，e=${e.toString()}');
    // }
  }

  // 发送消息
  void onBtnSendMsg() async {
    if (_sendMsgController.text.isNotEmpty) {
      // if (_connectedSocket != null) {
      //   _connectedSocket.add(utf8.encode(_sendMsgController.text)); // 发送UTF8数据
      // }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  @override
  void initState() {
    _serverTxtController.text = 'ws://127.0.0.1';
    _portTxtController.text = '23300';

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
          onPressed: () {
            // 断开已连接的socket
            // if (_connectedSocket != null) {
            //   _connectedSocket.close();
            //   _connectedSocket = null;
            // }
            //
            // // 断开监听socket
            // if (_serverSocket != null) {
            //   _serverSocket.close();
            //   _serverSocket = null;
            // }

            setState(() {});
          },
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
                width: 200,
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

          // 端口
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('主机端口：'),
              Container(
                width: 100,
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
                      controller: _portTxtController,
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 按钮
          createConnectButton(),
          // (_connectedSocket != null || _serverSocket != null)
          //     ? createDisconnectButton()
          //     : createConnectButton(),
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
    print(log);
    _recvMsg.add(log);
    setState(() {});
  }
}
