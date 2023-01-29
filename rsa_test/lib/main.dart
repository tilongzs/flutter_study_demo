import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';

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
      home: const MyHomePage(title: 'DES加密示例'),
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
  TextEditingController _sendMsgController = TextEditingController();

  late crypto.AsymmetricKeyPair _keyPair;
  var _rsaHelper = RsaKeyHelper();
  String  _encryptedString = "";

  @override
  void initState() {

    getKeyPair().then((value) {
      printLog('getKeyPair生成完成');
      
      _keyPair = value;
    },
    onError: (err){
      printLog('getKeyPair生成失败！');
    });

    super.initState();
  }

  // 打印日志
  void printLog(String log) {
    String finalLog = DateTime.now().toString() + " " + log;
    print(finalLog);
    _recvMsg.add(finalLog);
    setState(() {});
  }

  Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>> getKeyPair() {
    return _rsaHelper.computeRSAKeyPair(_rsaHelper.getSecureRandom());
  }

  void onBtnEncrypt(){
    if(_sendMsgController.text.isNotEmpty){
      _encryptedString = encrypt(_sendMsgController.text, _keyPair.publicKey as RSAPublicKey);
      printLog('加密完成：${_sendMsgController.text}');
    }else{
      printLog('请输入需要加密的字符串');
    }
  }

  void onBtnDecrypt(){
    if(_encryptedString.isNotEmpty){
      String decryptedString = decrypt(_encryptedString, _keyPair.privateKey as RSAPrivateKey);
      printLog('解密后字符串：${decryptedString}');
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
