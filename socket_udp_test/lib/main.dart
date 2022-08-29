import 'dart:convert';
import 'dart:io';
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
  final List<String> _recvMsg = []; // 接收到的消息
  final _recvMsgListHeight = 200.0;

  String _localIP = '127.0.0.1';  //本机局域网IP
  RawDatagramSocket? _bindSocket;

  TextEditingController _recvMsgController = TextEditingController(); // 接收消息文本控制器
  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _ipTxtController = TextEditingController(); //  连接服务器IP文本控制器
  TextEditingController _portTxtController = TextEditingController(); //  连接服务器端口文本控制器

  @override
  void initState() {
    super.initState();
    _ipTxtController.text = _localIP;
    _portTxtController.text = '23300';

    initIP();  // 尝试获取本机局域网IP
  }

  @override
  void dispose() {
    _recvMsgController.dispose();
    _sendMsgController.dispose();
    _ipTxtController.dispose();
    _portTxtController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UDP_Test'),
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
      _localIP = wifiIP == null ? "" : wifiIP;
    } on PlatformException {
      print('Failed to get broadcast IP.');
    } catch (e) {
      printLog('尝试获取本机局域网IP异常，e=${e.toString()}');
    }

    setState(() {
      _ipTxtController.text = _localIP;
    });
  }

  // 接收消息列表框
  Widget recvMsgListview() {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black12,
      ),
      height: _recvMsgListHeight,
      child: TextField(
        readOnly: true,
        controller: _recvMsgController,
        expands: true, // 填充父窗口
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(10)
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
  /*****************************************************************************/

  /// IP设置区域
  // bind、listen
  void onBtnListen() async{
    try{
      _bindSocket = await RawDatagramSocket.bind(_localIP,  int.parse(_portTxtController.text));
      _bindSocket?.listen(onSocketData, onError: onSocketError, onDone: onSocketDone);
    }catch(e){
      printLog('开始监听出现异常，e=${e.toString()}');
    }
  }

  // 关闭socket
  void onBtnCloseSocket(){
    _bindSocket?.close();
    _bindSocket = null;

    setState(() {});
  }

  // socket事件
  void onSocketData(RawSocketEvent e){
    switch(e){
      case RawSocketEvent.read:{
          if(_bindSocket != null){
            Datagram? dg = _bindSocket!.receive();
            if(dg != null){
              String msg = utf8.decode(dg!.data); // 将UTF8数据解码
              _recvMsgController.text += ("\r\n" + msg);
              printLog('收到来自${dg.address.toString()}:${dg.port}的数据：${dg.data.lengthInBytes}字节数据 内容:$msg');
            }
          }
         }
        break;
      case RawSocketEvent.write: {
          printLog('RawSocketEvent.write');
        }
        break;
      case RawSocketEvent.readClosed:{
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

  Widget IPSettingRect() {
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
                width: 200,
                height: 40,
                alignment: Alignment.centerLeft,
                child: TextField(
                  maxLines: 1,
                  controller: _ipTxtController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.only(left: 5),
                  ),
                  textAlignVertical: TextAlignVertical.center,
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
                width: 100,
                height: 40,
                child: TextField(
                  maxLines: 1,
                  controller: _portTxtController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.only(left: 5),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
            ],
          ),

          // 按钮
          Wrap(
            spacing: 10,
            children: [
              _bindSocket == null ? ElevatedButton(onPressed: onBtnListen, child: Text('监听')) : ElevatedButton(onPressed: onBtnCloseSocket, child: Text('关闭socket')),
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
        var remoteAddr = InternetAddress.tryParse(_ipTxtController.text);
        remoteAddr ??= InternetAddress("127.0.0.1");
        var remotePort = int.tryParse(_portTxtController.text);
        remotePort ??= 23300;
        _bindSocket!.send(utf8.encode(_sendMsgController.text),  remoteAddr, remotePort); // 发送
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 连续发送多条消息
  void onBtnSendmultipleMsg() {
    var data = utf8.encode(_sendMsgController.text);
    var remoteAddr = InternetAddress.tryParse(_ipTxtController.text);
    remoteAddr ??= InternetAddress("127.0.0.1");
    var remotePort = int.tryParse(_portTxtController.text);
    remotePort ??= 23300;
    if (_bindSocket != null) {
      for (int i = 0; i < 100; ++i) {
        _bindSocket!.send(data, remoteAddr, remotePort); // 发送
      }
    }
  }

  Widget sendMsgRect() {
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            // 多行输入区域
            height: 120,
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _sendMsgController,
              autofocus: true,
              expands: true, // 填充父窗口
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10)
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(onPressed: onBtnSendMsg, child: Text('发送消息')),
              ElevatedButton(onPressed: onBtnSendmultipleMsg, child: Text('发送多条消息')),
            ],
          ),
        ],
      ),
    );
  }

  Widget createMsgListview() {
    return NotificationListener<ScrollNotification>(
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
