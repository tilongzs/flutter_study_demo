import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
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
      home: const MyHomePage(title: 'RSA加密示例'),
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
  TextEditingController _recvMsgController = TextEditingController();
  ScrollController _recvScrollController = ScrollController();
  TextEditingController _sendMsgController = TextEditingController();

  late crypto.AsymmetricKeyPair _keyPair;
  var _rsaHelper = RsaKeyHelper();
  String  _encryptedString = "";

  @override
  void initState() {

    _recvMsgController.addListener(() {
      // 自动滚动至底部
      _recvScrollController.jumpTo(_recvScrollController.position.maxScrollExtent);
    });

    getKeyPair().then((value) {
      printLog('getKeyPair生成完成');
      
      _keyPair = value;
    },
    onError: (err){
      printLog('getKeyPair生成失败！');
    });

    super.initState();
  }

  @override
  void dispose() {
    _recvMsgController.dispose();
    _recvScrollController.dispose();
    _sendMsgController.dispose();
    super.dispose();
  }

  // 打印日志
  void printLog(String log) {
    log = DateTime.now().toString() + '\t' + log + '\n';
    print(log);
    _recvMsgController.text += log;
    setState(() {});
  }

  Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>> getKeyPair() {
    return _rsaHelper.computeRSAKeyPair(_rsaHelper.getSecureRandom());
  }

  void onBtnEncrypt(){
    if(_sendMsgController.text.isNotEmpty){
      // 先进行一次UTF8编码
      String utf8String = String.fromCharCodes(utf8.encode(_sendMsgController.text));
      // 加密
      _encryptedString = encrypt(utf8String, _keyPair.publicKey as RSAPublicKey);
      printLog('加密完成：${_sendMsgController.text}');
    }else{
      printLog('请输入需要加密的字符串');
    }
  }

  void onBtnDecrypt(){
    if(_encryptedString.isNotEmpty){
      // 解密
      String decryptedString = decrypt(_encryptedString, _keyPair.privateKey as RSAPrivateKey);
      // UTF8解码
      String str = utf8.decode(decryptedString.runes.toList());
      printLog('解密后字符串：${str}');
    }else{
      printLog('请先加密字符串');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            recvMsgListview(), // 接收消息列表框
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
              ElevatedButton(onPressed: onBtnEncrypt, child: Text('加密消息')),
              ElevatedButton(onPressed: onBtnDecrypt, child: Text('解密消息')),
            ],
          ),
        ],
      ),
    );
  }
}
