import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'TCPHandler.dart';
import 'netframe.dart';

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
  TCPHandler?	_tcpHandler;
  SocketData? _currentSocketData = null; // 已建立连接的socket

  TextEditingController _recvMsgController = TextEditingController(); //  接收消息文本控制器
  ScrollController      _recvMsgScrollController = ScrollController();
  ScrollController _recvScrollController = ScrollController(); //  接收消息文本滚动控制器
  TextEditingController _sendMsgController = TextEditingController(); //  发送消息文本控制器
  TextEditingController _IPTxtController = TextEditingController(); //  连接服务器IP文本控制器
  TextEditingController _portTxtController = TextEditingController(); //  连接服务器端口文本控制器

  @override
  void initState() {
    super.initState();

    // _recvMsgController.addListener(() {
    //   // 自动滚动至底部
    //   _recvScrollController.jumpTo(_recvScrollController.position.maxScrollExtent);
    // });

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

  void _onAccept(SocketData socketData) {
    _currentSocketData = socketData;

    printLog('新客户端已连接：${socketData.remoteIP}:${socketData.remotePort}');
  }

  void _onConnected(SocketData socketData) {
    _currentSocketData = socketData;

    printLog('连接TCP服务端成功：${socketData.remoteIP}:${socketData.remotePort}');
  }

  void _onDisconnect(SocketData socketData) {
    if(_currentSocketData == socketData){
      _currentSocketData = null;
      printLog('当前连接已断开');
    }
  }

  void _onRecv(SocketData socketData, LocalPackage localPackage) {
    printLog('收到：${localPackage.headInfo.size}字节数据');
  }

  void _onSend(SocketData socketData, LocalPackage localPackage) {
    printLog('已发送：${localPackage.headInfo.size}字节数据');
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
    _tcpHandler = TCPHandler(printLog);
    bool isSucess = await _tcpHandler!.listen(serverPot, _onAccept, _onDisconnect, _onRecv, _onSend);
    if(isSucess){
      printLog('开始监听');
    }else{
      printLog('开始监听失败');
    }
  }

  // 连接到Server
  void onBtnConnectToServer() async {
    var serverIP = _IPTxtController.text;
    var serverPot = int.parse(_portTxtController.text);
    _tcpHandler = TCPHandler(printLog);
    bool isSucess = await _tcpHandler!.connect(serverIP, serverPot, _onConnected, _onDisconnect, _onRecv, _onSend);
    if(isSucess){
      printLog('连接服务端成功');
    }else{
      printLog('连接服务端失败');
    }
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
            _tcpHandler?.stop();

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
          _currentSocketData != null
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
      if (_currentSocketData != null) {
        _tcpHandler?.sendList(_currentSocketData!, NetInfoType.NIT_Message, data: utf8.encode(_sendMsgController.text));
      }

      _sendMsgController.text = '';
      setState(() {});
    }
  }

  // 发送大缓存数据
  void onBtnSendBigBuffer() {
    /* var dataWriter = ByteDataWriter();
    dataWriter.writeUint8(1); // 1个字节
    _connectedSocket?.add(dataWriter.toBytes());*/

    var byteData = ByteData(1024 * 1024);
    if (_currentSocketData != null) {
      _tcpHandler?.sendList(_currentSocketData!, NetInfoType.NIT_Message, data: byteData.buffer.asUint8List());
    }
  }

  // 发送文件
  void onBtnSendFile() async{
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null) {
        final filePath = result.files.single.path;
        printLog("选中的文件路径：$filePath");

        if (_currentSocketData != null) {
          _tcpHandler?.sendList(_currentSocketData!, NetInfoType.NIT_File, filePath: filePath);
        }
      } else {
        printLog("未选择文件");
      }
    } catch (e) {
      printLog("选择文件时出错：$e");
      _tcpHandler?.stop();
    }
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
              ElevatedButton(onPressed: onBtnSendBigBuffer, child: Text('发送大缓存数据')),
              ElevatedButton(onPressed: onBtnSendFile, child: Text('发送文件')),
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
