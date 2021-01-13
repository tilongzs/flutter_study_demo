import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_ip/wifi_ip.dart';
import 'package:buffer/buffer.dart';

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

// 自定义滚动条
class _ScrollBar extends StatelessWidget {
  double _viewHeight = 1;
  double _parentHeight = 1;

  _ScrollBar(double viewHeight, double parentHeight) {
    _viewHeight = viewHeight;
    _parentHeight = parentHeight;
  }

  double GenerateHeight() {
    if (_viewHeight == 0) {
      return 0;
    } else {
      double height = _parentHeight * _parentHeight / _viewHeight;
      return height < 50 ? 50 : height;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: GenerateHeight(),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.blue),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.arrow_drop_up,
            size: 18,
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final List<String> _recvMsg = []; // 接收到的消息
  double _recvMsgScrollbarAlignmentY = -1; // 范围-1~1
  double _recvMsgMaxScrollExtent = 0;
  final _recvMsgListHeight = 200.0;

  String _localIP = '127.0.0.1';  //本机局域网IP
  Socket _connectedSocket; // 与服务器建立连接的socket
  ServerSocket _serverSocket;

  TextEditingController _sendMsgController =
      TextEditingController(); //  发送消息文本控制器
  TextEditingController _IPTxtController =
      TextEditingController(); //  连接服务器IP文本控制器
  TextEditingController _portTxtController =
      TextEditingController(); //  连接服务器端口文本控制器

  @override
  void initState() {
    super.initState();

    _IPTxtController.text = _localIP;
    _portTxtController.text = '23300';

    initIP();  // 尝试获取本机局域网IP
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
            createRecvMsgListview(), // 接收消息列表框
            createIPSettingRect(), // 设置IP、端口区域
            createSendMsgRect(), // 发送消息区域
          ],
        ),
      ),
    );
  }

  // 获取本机局域网IP
  void initIP() async{
    try {
      WifiIpInfo wifiInfo;
      wifiInfo = await WifiIp.getWifiIp;
      _localIP = wifiInfo.ip;
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
  Widget createRecvMsgListview() {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
        ),
        color: Colors.black12,
      ),
      height: _recvMsgListHeight,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          createMsgListview(), // 消息列表
          Container(
            // 滚动条
            alignment: Alignment(1, _recvMsgScrollbarAlignmentY),
            padding: EdgeInsets.only(right: 5),
            child: _ScrollBar(_recvMsgMaxScrollExtent + _recvMsgListHeight,
                _recvMsgListHeight),
          )
        ],
      ),
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
      _serverSocket.listen(onAccept,
          onError: onSocketError, onDone: onServerListemSocketClose);
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
      _connectedSocket.listen(onSocketRecv,
          onError: onSocketError, onDone: onSocketClose);

      printLog('与服务端建立连接');
      setState(() {});
    } catch (e) {
      printLog('连接socket出现异常，e=${e.toString()}');
    }
  }

  // 作为Server有新连接
  void onAccept(Socket socket) {
    _connectedSocket = socket;
    socket.listen(onSocketRecv, onError: onSocketError, onDone: onSocketClose);
    printLog('新客户端连接');
  }

  // 作为Server停止监听
  void onServerListemSocketClose() {
    _serverSocket = null;
    printLog('服务端停止监听');
  }

  // 接收到数据
  void onSocketRecv(Uint8List data) {
    var decoder = Utf8Decoder();
    String msg = decoder.convert(data); // 将UTF8数据解码
    printLog('收到：${data.length}字节数据 内容:$msg');
  }

  // socket关闭
  void onSocketClose() {
    _connectedSocket = null;
    printLog('断开连接');
  }

  // socket错误
  void onSocketError(Object error) {
    printLog('与服务端已连接的socket出现错误，error=${error.toString()}');
  }

  Widget createIPSettingRect() {
    Function createConnectButton = () {
      return Wrap(
        spacing: 10,
        children: [
          RaisedButton(onPressed: onBtnListen, child: Text('监听')),
          RaisedButton(onPressed: onBtnConnectToServer, child: Text('连接'))
        ],
      );
    };

    Function createDisconnectButton = () {
      return RaisedButton(
          onPressed: () {
            // 断开已连接的socket
            if (_connectedSocket != null) {
              _connectedSocket.close();
              _connectedSocket = null;
            }

            // 断开监听socket
            if (_serverSocket != null) {
              _serverSocket.close();
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
                      controller: _IPTxtController,
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
                // 端口输入区域
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
        var encoder = Utf8Encoder(); // 创建UTF8转换器，以支持发送中文
        _connectedSocket.add(encoder.convert(_sendMsgController.text)); // 发送
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 连续发送多条消息
  void onBtnSendmultipleMsg() {
    for (int i = 0; i < 100; ++i) {
      _connectedSocket.writeln("onBtnSendmultipleMsg");
    }
  }

  // 发送大缓存数据
  void onBtnSendBigBuffer(){
   /* var dataWriter = ByteDataWriter();
    dataWriter.writeUint8(1); // 1个字节
    _connectedSocket.add(dataWriter.toBytes());*/

    var byteData = ByteData(1024*1024);
    _connectedSocket.add(byteData.buffer.asUint8List());
  }

  Widget createSendMsgRect() {
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
              RaisedButton(onPressed: onBtnSendMsg, child: Text('发送消息')),
              RaisedButton(onPressed: onBtnSendmultipleMsg, child: Text('发送多条消息')),
              RaisedButton(onPressed: onBtnSendBigBuffer, child: Text('发送大缓存数据')),
            ],
          ),
        ],
      ),
    );
  }

  // 展示接收到的消息Listview
  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    // printLog('滚动组件最大滚动距离:${metrics.maxScrollExtent}');
    // printLog('当前滚动位置:${metrics.pixels}');

    _recvMsgMaxScrollExtent = metrics.maxScrollExtent == double.infinity
        ? 0
        : metrics.maxScrollExtent;
    _recvMsgScrollbarAlignmentY = metrics.maxScrollExtent == 0
        ? -1
        : -1 + (metrics.pixels / metrics.maxScrollExtent) * 2;
    // printLog('_alignmentY:$_alignmentY');

    setState(() {});
    return true;
  }

  Widget createMsgListview() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Text(_recvMsg[index]);
        },
        itemCount: _recvMsg.length,
      ),
    );
  }
  /**********************************************************************/

  // 打印日志
  void printLog(String log) {
    print(log);
    _recvMsg.add(log);
    setState(() {});
  }
}
