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

  var _recvTotalCount = 0;

  String _localIP = '127.0.0.1';  //本机局域网IP
  RawSocket _connectedSocket = null; // 已建立连接的socket
  RawServerSocket _serverSocket = null;  // 服务器监听socket

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
      _serverSocket = await RawServerSocket.bind(
          InternetAddress.tryParse(serverIP), serverPot);

      // 开始监听
      _serverSocket.listen(onServerSocketData,  onError: onSocketError, onDone: onServerSocketDone);
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
      _connectedSocket = await RawSocket.connect(serverIP, serverPot,
          timeout: Duration(milliseconds: 500));
      _connectedSocket.listen(onSocketData, onError: onSocketError, onDone: onSocketClose);

      printLog('与服务端建立连接');
      setState(() {});
    } catch (e) {
      printLog('连接socket出现异常，e=${e.toString()}');
    }
  }

  // 作为Server有新连接（Accept）
  void onServerSocketData(RawSocket socket) {
    _connectedSocket = socket;
    _connectedSocket.listen(onSocketData, onError: onSocketError, onDone: onSocketClose);

    printLog('有新客户端连接：${_connectedSocket.remoteAddress.address}:${_connectedSocket.remotePort}');
  }

  // 作为Server停止监听
  void onServerSocketDone() {
    _serverSocket = null;
    printLog('服务端停止监听');
  }

  // socket事件
  void onSocketData(RawSocketEvent socketEvent) {
    switch(socketEvent){
      case RawSocketEvent.read:
        {
          printLog('RawSocketEvent.read');
          var buffer = BytesBuffer();
          var availableLen = _connectedSocket.available();
          do{
            Uint8List data = _connectedSocket.read(availableLen);
            if (null != data) {
              buffer.add(data);
            }else{
              break;
            }

            availableLen = _connectedSocket.available();
          }while (availableLen != 0);

          String msg = utf8.decode(buffer.toBytes()); // 将UTF8数据解码
          printLog('收到：${buffer.length}字节数据 内容:$msg');

          _recvTotalCount += (buffer.length as int);
         // printLog('共收到：$_recvTotalCount字节数据');
        }
        break;
      case RawSocketEvent.write:
        {
          printLog('RawSocketEvent.write');
        }
        break;
      case RawSocketEvent.readClosed:
        {
          printLog('RawSocketEvent.readClosed');
          _connectedSocket.close(); // 对方主动断开连接
        }
        break;
      case RawSocketEvent.closed:
        {
          printLog('RawSocketEvent.closed');
        }
        break;
    }
  }

  // socket关闭
  void onSocketClose() {
    _connectedSocket.close();
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
        _connectedSocket.write(utf8.encode(_sendMsgController.text)); // 发送UTF8数据
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 发送大缓存数据
  void onBtnSendBigBuffer(){
    var byteData = ByteData(1024*1024*4);
    int remainBytes = byteData.lengthInBytes;
    int hasSentBytes = 0; // 已发送字节数
    const maxSendBytes = 65536; // 单次发送最大字节数
    int currentSendBytes = maxSendBytes; // 当前将要发送字节数
    int sentBytes = 0; // 当前实际发送字节数
    do{
      if (remainBytes < currentSendBytes) {
        currentSendBytes = remainBytes;
      }

      sentBytes = _connectedSocket.write(byteData.buffer.asUint8List(), hasSentBytes, currentSendBytes);
      hasSentBytes += sentBytes;
      remainBytes -= sentBytes;
    }while(remainBytes != 0);
    printLog('onBtnSendBigBuffer完成，共发送${hasSentBytes}字节数据');
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
