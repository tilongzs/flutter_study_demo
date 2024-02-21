import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _recvMsgListHeight = 200.0;

  String _localIP = '127.0.0.1'; //本机局域网IP
  Socket? _connectedSocket = null; // 已建立连接的socket
  ServerSocket? _serverSocket = null; // 服务器监听socket

  TextEditingController _recvMsgController = TextEditingController(); //  接收消息文本控制器
  ScrollController      _recvMsgScrollController = ScrollController();
  ScrollController _recvScrollController = ScrollController(); //  接收消息文本滚动控制器
  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _IPTxtController = TextEditingController(); //  连接服务器IP文本控制器
  TextEditingController _portTxtController = TextEditingController(); //  连接服务器端口文本控制器

  @override
  void initState() {
    super.initState();

    _recvMsgController.addListener(() {
      // 自动滚动至底部
      _recvScrollController.jumpTo(_recvScrollController.position.maxScrollExtent);
    });

    _IPTxtController.text = _localIP;
    _portTxtController.text = '23300';
    initIP(); // 尝试获取本机局域网IP
  }

  @override
  void dispose() {
    _recvMsgController.dispose();
    _recvScrollController.dispose();
    _sendMsgController.dispose();
    _IPTxtController.dispose();
    _portTxtController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TCP_Test'),
      ),
      body: Center(
        child: Column(
          children: [
            recvMsgListview(), // 接收消息列表框
            IPSettingRect(), // 设置IP、端口区域
            sendMsgRect(), // 发送消息区域
          ],
        ),
      ),
    );
  }

  // 获取本机局域网IP
  void initIP() async{
    try {
      final wifiInfo = NetworkInfo();
      var wifiIP = await wifiInfo.getWifiIP();
      if (wifiIP != null){
        if (wifiIP.isNotEmpty){
          _localIP = wifiIP;
          printLog('获取到本机局域网IP ${_localIP}');
        }else{
          printLog('wifiInfo.getWifiIP()获取本机局域网IP为空');
        }
      }else{
        printLog('尝试获取本机局域网IP失败');
      }
    } on PlatformException {
      print('Failed to get broadcast IP.');
    } catch (e) {
      printLog('尝试获取本机局域网IP异常，e=${e.toString()}');
    }

    setState(() {
      _IPTxtController.text = _localIP;
    });
  }

  // 接收消息列表框
  Widget recvMsgListview() {
    return Container(
          margin: EdgeInsets.all(10),
          height: _recvMsgListHeight,
          child: TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            expands: true,
            readOnly: true,
            controller: _recvMsgController,
            scrollController: _recvScrollController,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              isDense: true,
              border: const OutlineInputBorder(
                gapPadding: 0,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                  width: 1,
                  style: BorderStyle.none,
                ),
              ),
            ),
          )
      );
  }
  /*****************************************************************************/

  /// IP设置区域
  // 作为Server开始监听
  void onBtnListen() async {
    var serverIP = _IPTxtController.text;
    var serverPot = int.parse(_portTxtController.text);
    try {
      _serverSocket = await ServerSocket.bind(
          InternetAddress.tryParse(serverIP), serverPot);

      // 开始监听
      _serverSocket?.listen(onServerSocketData,
          onError: onSocketError,
          onDone: onServerSocketDone,
          cancelOnError: true);
      setState(() {});
      printLog('开始监听');
    } catch (e) {
      printLog('监听socket出现异常，e=${e.toString()}');
    }
  }

  // 连接到Server
  void onBtnConnectToServer() async {
    var serverIP = _IPTxtController.text;
    var serverPot = int.parse(_portTxtController.text);
    try {
      _connectedSocket = await Socket.connect(serverIP, serverPot,
          timeout: Duration(milliseconds: 500));
      _connectedSocket?.listen(onSocketData,
          onError: onSocketError, onDone: onSocketDone);

      printLog('与服务端建立连接');
      setState(() {});
    } catch (e) {
      printLog('连接socket出现异常，e=${e.toString()}');
    }
  }

  // 作为Server有新连接（Accept）
  void onServerSocketData(Socket socket) {
    _connectedSocket = socket;
    _connectedSocket?.listen(onSocketData,
        onError: onSocketError, onDone: onSocketDone);

    printLog(
        '有新客户端连接：${_connectedSocket?.remoteAddress.address}:${_connectedSocket?.remotePort}');
  }

  // 作为Server停止监听
  void onServerSocketDone() {
    _serverSocket = null;
    printLog('服务端停止监听');
  }

  // 接收到数据
  void onSocketData(Uint8List data) {
    String msg = utf8.decode(data); // 将UTF8数据解码
    printLog('收到：${data.lengthInBytes}字节数据 内容:$msg');
  }

  // socket关闭
  void onSocketDone() {
    _connectedSocket?.close();
    _connectedSocket = null;
    printLog('断开连接');
  }

  // socket错误
  void onSocketError(Object error) {
    printLog('与服务端已连接的socket出现错误，error=${error.toString()}');
  }

  Widget IPSettingRect() {
    Function createConnectButton = () {
      return Wrap(
        spacing: 10,
        children: [
          ElevatedButton(onPressed: onBtnListen, child: Text('监听')),
          ElevatedButton(onPressed: onBtnConnectToServer, child: Text('连接'))
        ],
      );
    };

    Function createDisconnectButton = () {
      return ElevatedButton(
          onPressed: () {
            // 断开已连接的socket
            if (_connectedSocket != null) {
              _connectedSocket?.close();
              _connectedSocket = null;
            }

            // 断开监听socket
            if (_serverSocket != null) {
              _serverSocket?.close();
              _serverSocket = null;
            }

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
          // IP地址
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('主机IP：'),
              Container(
                // 端口输入区域
                width: 200,
                height: 30,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                  ),
                  color: Colors.white,
                ),
                child: TextField(
                  maxLines: 1,
                  controller: _IPTxtController,
                  decoration:
                      InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
            ],
          ),

          // 端口
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('主机端口：'),
              SizedBox(
                // 端口输入区域
                width: 100,
                height: 30,
                child: TextField(
                  maxLines: 1,
                  controller: _portTxtController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(0)),
                      )),
                ),
              ),
            ],
          ),

          // 按钮
          (_connectedSocket != null || _serverSocket != null)
              ? createDisconnectButton()
              : createConnectButton(),
        ],
      ),
    );
  }
  /********************************************************************/

  /// 发送消息区域，包含发送输入区域和发送按钮
  // 发送消息
  void onBtnSendMsg() async {
    if (_sendMsgController.text.isNotEmpty) {
      if (_connectedSocket != null) {
        _connectedSocket?.add(utf8.encode(_sendMsgController.text)); // 发送UTF8数据
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 连续发送多条消息
  void onBtnSendmultipleMsg() {
    for (int i = 0; i < 100; ++i) {
      _connectedSocket?.writeln("onBtnSendmultipleMsg");
    }
  }

  // 发送大缓存数据
  void onBtnSendBigBuffer() {
    /* var dataWriter = ByteDataWriter();
    dataWriter.writeUint8(1); // 1个字节
    _connectedSocket?.add(dataWriter.toBytes());*/

    var byteData = ByteData(1024 * 1024);
    _connectedSocket?.add(byteData.buffer.asUint8List());
  }

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
              ElevatedButton(
                  onPressed: onBtnSendmultipleMsg, child: Text('发送多条消息')),
              ElevatedButton(
                  onPressed: onBtnSendBigBuffer, child: Text('发送大缓存数据')),
            ],
          ),
        ],
      ),
    );
  }
  /**********************************************************************/

  // 打印日志
  void printLog(String log) {
    setState(() {
      log = '${DateTime.now()}\t$log';
      print(log);
      log += '\n';
      _recvMsgController.text += log;

      if (_recvMsgScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 30), () { // 延迟等待位置数据更新
          _recvMsgScrollController.jumpTo(
            _recvMsgScrollController.position.maxScrollExtent, //滚动到底部
          );
        });
      }
    });
  }
}
