import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  String _multicastIP = '239.233.233.1';  // 组播IP
  RawDatagramSocket _bindSocket;

  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _ipMulticastTxtController = TextEditingController(); //  组播IP文本控制器
  TextEditingController _portTxtController = TextEditingController(); //  连接服务器端口文本控制器

  @override
  void initState() {
    super.initState();

    _ipMulticastTxtController.text = _multicastIP;
    _portTxtController.text = '23300';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multicast_Test'),
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
  // bind、listen
  void onBtnListen() async{
    try{
      _bindSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4,  int.parse(_portTxtController.text));
      _bindSocket.joinMulticast(InternetAddress(_ipMulticastTxtController.text));
      _bindSocket.listen(onSocketData, onError: onSocketError, onDone: onSocketDone);
    }catch(e){
      printLog('开始监听出现异常，e=${e.toString()}');
    }
  }

  // 关闭socket
  void onBtnCloseSocket(){
    _bindSocket.close();
    _bindSocket = null;

    setState(() {});
  }

  // socket事件
  void onSocketData(RawSocketEvent e){
    switch(e){
      case RawSocketEvent.read: {
          Datagram dg = _bindSocket.receive();
          String msg = utf8.decode(dg.data); // 将UTF8数据解码
          printLog('收到来自${dg.address.toString()}:${dg.port}的数据：${dg.data.lengthInBytes}字节数据 内容:$msg');
        }
        break;
      case RawSocketEvent.write: {
          printLog('RawSocketEvent.write');
        }
        break;
      case RawSocketEvent.readClosed: {
          printLog('RawSocketEvent.readClosed');
        }
        break;
      case RawSocketEvent.closed: {
          printLog('RawSocketEvent.closed');
        }
        break;
    }
  }

  // socket关闭
  void onSocketDone() {
    _bindSocket = null;
    printLog('socket关闭');
  }

  // socket错误
  void onSocketError(Object error) {
    printLog('socket出现错误，error=${error.toString()}');
  }

  Widget createIPSettingRect() {
    return Container(
      margin: EdgeInsets.all(10),
      child: Wrap(
        direction: Axis.vertical,
        spacing: 10,
        children: [
          // 组播IP地址
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('组播IP：'),
              Container(
                // IP输入区域
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
                      controller: _ipMulticastTxtController,
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
          Wrap(
            spacing: 10,
            children: [
              _bindSocket == null ? RaisedButton(onPressed: onBtnListen, child: Text('监听')) : RaisedButton(onPressed: onBtnCloseSocket, child: Text('关闭socket')),
            ],
          )
        ],
      ),
    );
  }
  /********************************************************************/

  /// 发送消息区域，包含发送输入区域和发送按钮
  // 发送消息
  void onBtnSendMsg() async {
    if (_sendMsgController.text.isNotEmpty) {
      if (_bindSocket != null) {
        _bindSocket.send(utf8.encode(_sendMsgController.text),  InternetAddress(_ipMulticastTxtController.text),  int.tryParse(_portTxtController.text)); // 发送
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 连续发送多条消息
  void onBtnSendmultipleMsg() {
    if (_sendMsgController.text.isNotEmpty) {
      var data = utf8.encode(_sendMsgController.text);
      for (int i = 0; i < 100; ++i) {
        _bindSocket.send(data,  InternetAddress(_ipMulticastTxtController.text),  int.tryParse(_portTxtController.text)); // 发送
      }
    }
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
