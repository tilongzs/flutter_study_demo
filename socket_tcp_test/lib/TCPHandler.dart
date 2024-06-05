import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'netframe.dart';

class TCPHandler {
  InternetAddress _localAddr =  InternetAddress.anyIPv4;
  int _localPort = 0;
  ServerSocket? _serverSocket; // TCP 监听socket
  var _connectedSocketsData = Map<int /*SocketID*/, SocketData>();

  void Function(String)? _cbLog; // 日志
  void Function(SocketData)? _cbOnAccept;
  void Function(SocketData)? _cbOnConnected;
  void Function(SocketData)? _cbOnDisconnect;
  void Function(SocketData, LocalPackage)? _cbOnRecv;
  void Function(SocketData, LocalPackage)? _cbOnSend;

  get localPort => _localPort;
  void _log(String strLog) => _cbLog?.call('TCPHandler::' + strLog);

  TCPHandler(void Function(String) cbLog){
    _cbLog = cbLog;
  }

  Future<bool> listen(int localPort,
      void Function(SocketData) cbOnAccept,
      void Function(SocketData) cbOnDisconnected,
      void Function(SocketData, LocalPackage) cbOnRecv,
      void Function(SocketData, LocalPackage)? cbOnSend,
      {String? localIP, bool isUseSSL = false}) async {
    _cbOnAccept = cbOnAccept;
    _cbOnDisconnect = cbOnDisconnected;
    _cbOnRecv = cbOnRecv;
    _cbOnSend = cbOnSend;

    if (localIP != null) {
      try{
        _localAddr = InternetAddress(localIP);
      } catch (e) {
        _log('listen 本地IP出现异常，localIP:$localIP e:${e.toString()}');
        return false;
      }
    }
    _localPort = localPort;

    try {
      _serverSocket = await ServerSocket.bind(_localAddr, _localPort);
      if(null == _serverSocket){
        return false;
      }
      _localPort = _serverSocket!.port; // 获取实际端口
      _serverSocket!.listen(_onAccept, onError: _onServerListenSocketError, onDone: _onListenSocketClose);

      return true;
    } catch (e) {
      _log('listen TCP监听socket出现异常，e:${e.toString()}');
    }

    return false;
  }

  void stop() async {
    if (null != _serverSocket) {
      _serverSocket!.close();
      _serverSocket = null;
    }

    _connectedSocketsData.forEach((id, socketData){
      socketData.close();
    });
  }

  Future<bool> connect(String remoteIP, int remotePort,
      void Function(SocketData) cbOnConnected,
      void Function(SocketData) cbOnDisconnected,
      void Function(SocketData, LocalPackage) cbOnRecv,
      void Function(SocketData, LocalPackage)? cbOnSend,
      {int timeout = 500, bool isUseSSL = false}) async {
    _cbOnConnected = cbOnConnected;
    _cbOnDisconnect = cbOnDisconnected;
    _cbOnRecv = cbOnRecv;
    _cbOnSend = cbOnSend;

    try {
      var socketData = SocketData();
      socketData.remoteIP = remoteIP;
      socketData.remotePort = remotePort;
      if(isUseSSL){
        socketData.sock = await SecureSocket.connect(remoteIP, remotePort,
            timeout: Duration(milliseconds: timeout), onBadCertificate: (X509Certificate){
              // 仅调试用，不校验，以便允许自签名证书
              return true;
            });
      }else{
        socketData.sock = await Socket.connect(remoteIP, remotePort,
            timeout: Duration(milliseconds: timeout));
      }

      // 连接成功
      socketData.signalOnData.add(_onData);
      socketData.signalOnClose.add(_onClose);
      socketData.signalOnLog.add(_onLog);
      socketData.sock?.listen(socketData.onData,
          onError: socketData.onError, onDone: socketData.onClose);

      socketData.setConnected(true);
      _connectedSocketsData[socketData.id] = socketData;

      // 通知
      _cbOnConnected?.call(socketData);

      // 发送心跳
      // var heartbeatIOData = socketData.GetIOData(NetAction.ACTION_SEND,
      //     netInfoType: NetInfoType.NIT_Heartbeat);
      // if (null != heartbeatIOData) {
      //   Send(heartbeatIOData);
      // }

      return true;
    } catch (e) {
      // 连接失败
      _log('connect 异常，e:${e.toString()}');
    }

    return false;
  }

  bool sendList(SocketData socketData, NetInfoType netInfoType, {Uint8List? data, String? filePath}){
    if(filePath != null){
      File file = File(filePath);
      if(file.existsSync()){
        String fileName = path.basename(filePath);
        Uint8List tmpFileName = utf8.encode(fileName);
        FileInfo fileInfo = FileInfo();
        fileInfo.fileName.setRange(0, tmpFileName.length, tmpFileName);
        fileInfo.fileLength = file.lengthSync();

        IOData ioData = socketData.getIOData(NetAction.ACTION_SEND, netInfoType, data:data, fileInfo: fileInfo, filePath: filePath);
        return _sendList(ioData);
      }else{
        _log('sendList文件不存在 filePath:${filePath}');
      }

      return false;
    }else{
      IOData ioData = socketData.getIOData(NetAction.ACTION_SEND, netInfoType, data:data);
      return _sendList(ioData);
    }
  }

  // 作为TCP Server有新连接
  void _onAccept(Socket socket) {
    var socketData = SocketData();
    socketData.sock = socket;
    socketData.remoteIP = socket.remoteAddress.address;
    socketData.remotePort = socket.remotePort;
    socketData.signalOnData.add(_onData);
    socketData.signalOnClose.add(_onClose);
    socketData.signalOnLog.add(_onLog);
    socketData.setConnected(true);
    _connectedSocketsData[socketData.id] = socketData;

    socket.listen(socketData.onData, onError: socketData.onError, onDone: socketData.onClose, cancelOnError: true);

    // 发送心跳
    // var ioData = socketData.GetIOData(NetAction.ACTION_SEND,
    //     netInfoType: NetInfoType.NIT_Heartbeat);
    // if (ioData != null) {
    //   Send(ioData);
    // }

    // 通知
    _cbOnAccept?.call(socketData);
  }

  // 作为TCP Server有错误发生
  void _onServerListenSocketError(Object error) {
    _log('监听socket出现错误，error=${error.toString()}');
  }

  // 作为TCP Server停止监听
  void _onListenSocketClose() {
    if (null != _serverSocket) {
      _serverSocket = null;
    }
    _log('停止监听');
  }

  void _onLog([arguments]) {
    String strLog = arguments[0] as String;
    _log(strLog);
  }

  void _onData([arguments]) {
    SocketData socketData = arguments[0] as SocketData;
    Uint8List data = arguments[1] as Uint8List;
    _onRecv(socketData, data);
  }

  // 接收到新数据
  void _onRecv(SocketData socketData, Uint8List data) async {
    var onError = (NetDisconnectCode code, String errMsg) {
      socketData.resetRecvIOData();
      socketData.sock?.close();
      _log('onRecv code:$code errMsg:$errMsg');
    };

    IOData recvIOData = socketData.getRecvIOData();
    // 重置接收心跳时间
    socketData.resetHeartbeatRecv(DateTime.now().millisecondsSinceEpoch);

    // 处理数据
    int nodeNeedRcvBytes = 0;
    int nodeHasRcvBytes = 0;
    int nodeRemainWaitBytes = 0;
    int bufRemainSize = data.lengthInBytes;
    var reader = ByteDataReader(endian: Endian.little);
    reader.add(data);
    while (bufRemainSize != 0) {
      // 处理头部数据（PackageBase）
      if (0 != recvIOData.localPackage.tpStartTime) {
        recvIOData.localPackage.tpStartTime = DateTime.now().millisecondsSinceEpoch;
      }

      if ((recvIOData.localPackage.receivedBytes < PackageBase.classSize)) {
        nodeNeedRcvBytes = PackageBase.classSize;
        nodeHasRcvBytes = recvIOData.localPackage.receivedBytes; // TCP只发送一次头部数据，而且由于存在粘包，所以头部数据可能不会一次就接收完毕

        // 计算节点剩余待读取字节数
        nodeRemainWaitBytes = nodeNeedRcvBytes - nodeHasRcvBytes;
        if (nodeRemainWaitBytes > bufRemainSize) {
          nodeRemainWaitBytes = bufRemainSize;
        }

        // 读取数据
        Uint8List readData = reader.read(nodeRemainWaitBytes);
        recvIOData.localPackage.buffer.add(readData, copy: true); // 将读取到的数据缓存

        nodeHasRcvBytes += nodeRemainWaitBytes;
        recvIOData.localPackage.receivedBytes += nodeRemainWaitBytes;
        bufRemainSize -= nodeRemainWaitBytes;

        if (nodeHasRcvBytes == nodeNeedRcvBytes){
          PackageBase? tmpHeadInfo = PackageBase.fromBytes(recvIOData.localPackage.buffer.toBytes());
          if(tmpHeadInfo != null){
            recvIOData.localPackage.headInfo = tmpHeadInfo;
          }else{
            // 头部数据未接收完成
            onError(NetDisconnectCode.HeadinfoError, "PackageBase.fromBytes失败");
            return;
          }
        }
        else {
          // 头部数据未接收完成
          return;
        }
      }

      // 检查头部数据
      if (0 == recvIOData.localPackage.headInfo.size){
        onError(NetDisconnectCode.HeadinfoError, "onRecv headInfo.size==0");
        return;
      }

      if (NetInfoType.NIT_NULL == recvIOData.localPackage.headInfo.netInfoType){
        onError(NetDisconnectCode.HeadinfoError, "onRecv NIT_NULL");
        return;
      }

      if ((recvIOData.localPackage.headInfo.size > MAX_NET_PACKAGE_SIZE) && (NetDataType.NDT_Memory == recvIOData.localPackage.headInfo.dataType)){
        // 数据包过大（非文件）
        onError(NetDisconnectCode.HeadinfoError, "onRecv too big");
        return;
      }
      /*******************************************************************************************************************/

      // 处理内容
      switch (recvIOData.localPackage.headInfo.dataType) {
        case NetDataType.NDT_File:
        case NetDataType.NDT_MemoryAndFile: {
            // 文件类型
            // 接收文件基本信息(FileInfo)
            if (recvIOData.localPackage.receivedBytes < PackageBase.classSize + FileInfo.classSize){
              nodeNeedRcvBytes = FileInfo.classSize;
              nodeHasRcvBytes = (recvIOData.localPackage.receivedBytes - PackageBase.classSize).toInt();

              if (recvIOData.localPackage.package1Size == 0){
                recvIOData.localPackage.package1Size = FileInfo.classSize;
                recvIOData.localPackage.buffer = BytesBuffer();// 重置buffer
              }

              // 计算节点剩余待读取字节数
              nodeRemainWaitBytes = nodeNeedRcvBytes - nodeHasRcvBytes;
              if (nodeRemainWaitBytes > bufRemainSize){
                nodeRemainWaitBytes = bufRemainSize;
              }

              // 读取数据
              Uint8List readData = reader.read(nodeRemainWaitBytes);
              recvIOData.localPackage.buffer.add(readData, copy: true);

              nodeHasRcvBytes += nodeRemainWaitBytes;
              recvIOData.localPackage.receivedBytes += nodeRemainWaitBytes;
              bufRemainSize -= nodeRemainWaitBytes;

              if (nodeHasRcvBytes == nodeNeedRcvBytes){
                FileInfo? fileInfo = FileInfo.fromBytes(recvIOData.localPackage.buffer.toBytes());
                if(fileInfo != null){
                  recvIOData.localPackage.fileInfo = fileInfo;
                }else{
                  // 头部数据未接收完成
                  onError(NetDisconnectCode.Unknown, "FileInfo.fromBytes失败");
                  return;
                }

                // 生成本地文件路径
                String dirPath = '';
                await getDownloadsDirectory().then((directory){
                  if(directory != null){
                    dirPath = path.absolute(directory.path, 'download');
                    var fileName = fileInfo.fileName.where((byte) => byte != 0).toList(); // 过滤掉末尾的 0 字节
                    recvIOData.localPackage.filePath = path.absolute(dirPath, utf8.decode(fileName));

                    // 删除之前的文件
                    File file = File(recvIOData.localPackage.filePath!);
                    if(file.existsSync()){
                      file.deleteSync();
                    }

                    _log('onRecv start recv file...${recvIOData.localPackage.filePath}');
                  }else{
                    onError(NetDisconnectCode.Unknown, "获取下载文件夹路径 directory==null");
                    return;
                  }
                }, onError: (data, stackTrace){
                  onError(NetDisconnectCode.Unknown, "获取下载文件夹路径失败");
                  return;
                });
              }
              else
              {
                break;
              }
            }

            if (0 == bufRemainSize)
            {
              break;
            }
            /*************************************************************************************************************************************************/

            // 接收附加内存数据
            if (NetDataType.NDT_MemoryAndFile == recvIOData.localPackage.headInfo.dataType) {
              if (recvIOData.localPackage.receivedBytes < recvIOData.localPackage.headInfo.size - recvIOData.localPackage.fileInfo!.fileLength) {
                nodeNeedRcvBytes = (recvIOData.localPackage.headInfo.size - PackageBase.classSize - FileInfo.classSize - recvIOData.localPackage.fileInfo!.fileLength).toInt();
                nodeHasRcvBytes = (recvIOData.localPackage.receivedBytes - PackageBase.classSize - FileInfo.classSize).toInt();

                if (recvIOData.localPackage.package2Size == 0){
                  recvIOData.localPackage.package2Size = nodeNeedRcvBytes;
                  recvIOData.localPackage.buffer = BytesBuffer();// 重置buffer
                }
      
                // 计算节点剩余待读取字节数
                nodeRemainWaitBytes = nodeNeedRcvBytes - nodeHasRcvBytes;
                if (nodeRemainWaitBytes > bufRemainSize){
                  nodeRemainWaitBytes = bufRemainSize;
                }

                // 读取数据
                Uint8List readData = reader.read(nodeRemainWaitBytes);
                recvIOData.localPackage.buffer.add(readData, copy: true);

                nodeHasRcvBytes += nodeRemainWaitBytes;
                recvIOData.localPackage.receivedBytes += nodeRemainWaitBytes;
                bufRemainSize -= nodeRemainWaitBytes;

                if (nodeHasRcvBytes == nodeNeedRcvBytes) {
                  recvIOData.localPackage.package2 = recvIOData.localPackage.buffer.toBytes(copy: true);
                }else{
                  break;
                }
              }
            }
      
            if (0 == bufRemainSize)
            {
              break;
            }
            /*************************************************************************************************************************************************/

            // 接收文件
            nodeNeedRcvBytes = recvIOData.localPackage.fileInfo!.fileLength;
            if (NetDataType.NDT_MemoryAndFile == recvIOData.localPackage.headInfo.dataType) {
              nodeHasRcvBytes = (recvIOData.localPackage.receivedBytes - PackageBase.classSize - FileInfo.classSize - recvIOData.localPackage.package2Size).toInt();
            }
            else {
              nodeHasRcvBytes = (recvIOData.localPackage.receivedBytes - PackageBase.classSize - FileInfo.classSize).toInt();
            }

            // 计算节点剩余待读取字节数
            nodeRemainWaitBytes = nodeNeedRcvBytes - nodeHasRcvBytes;
            if (nodeRemainWaitBytes > bufRemainSize) {
              nodeRemainWaitBytes = bufRemainSize;
            }

            // 读取数据
            Uint8List readData = reader.read(nodeRemainWaitBytes);

            File file = File(recvIOData.localPackage.filePath!);
            try {
              file.createSync(recursive: true);
              RandomAccessFile randomAccessFile = file.openSync(mode: FileMode.append);
              randomAccessFile.setPositionSync(file.lengthSync());
              randomAccessFile.writeFromSync(readData);
              randomAccessFile.closeSync();
            }catch(e){
              onError(NetDisconnectCode.CreateWriteFileError, '文件写入时发生异常 e:' + e.toString());
              file.delete();
            }

            nodeHasRcvBytes += nodeRemainWaitBytes;
            recvIOData.localPackage.receivedBytes += nodeRemainWaitBytes;
            bufRemainSize -= nodeRemainWaitBytes;

            if (nodeHasRcvBytes == nodeNeedRcvBytes){
              // 保存结束时间
              recvIOData.localPackage.tpEndTime = DateTime.now().millisecondsSinceEpoch;

              // 保存最新IO序号
              socketData.recvIONumber = recvIOData.localPackage.headInfo.ioNum;

              // 通知接收完成
              _cbOnRecv?.call(recvIOData.socketData, recvIOData.localPackage);

              // 回复确认
              if (recvIOData.localPackage.headInfo.needConfirm) {
                _replyConfirm(socketData, recvIOData.localPackage.headInfo.ioNum);
              }

              // 清空接收缓存区
              recvIOData.localPackage.clear();
              continue;
            }
            else
            {
              break;
            }
          }
        case NetDataType.NDT_Memory:
          {
            switch (recvIOData.localPackage.headInfo.netInfoType) {
              case NetInfoType.NIT_Heartbeat:{
                  // 清空接收缓存区
                  recvIOData.localPackage.clear();
                  continue;
                }
              case NetInfoType.NIT_AutoConfirm:{
                  IOData? sendIOData = socketData.getWaitSendIOData();
                  if(null != sendIOData && sendIOData.localPackage.headInfo.ioNum == recvIOData.localPackage.headInfo.ioNum){
                    // 从发送列表中移除头部ioData
                    socketData.onSendComplete();
                  }

                  recvIOData.localPackage.clear();

                  // 继续发送
                  sendIOData = socketData.getWaitSendIOData();
                  if (null != sendIOData)
                  {
                    _send(sendIOData);
                  }
                  else
                  {
                    socketData.isSending = false;
                  }
                  continue;
                }
              default: {
                // 其他类型
                nodeNeedRcvBytes = (recvIOData.localPackage.headInfo.size - PackageBase.classSize).toInt();
                nodeHasRcvBytes = (recvIOData.localPackage.receivedBytes - PackageBase.classSize).toInt();

                // 没有Package数据
                if (0 == nodeNeedRcvBytes){
                  // 保存结束时间
                  recvIOData.localPackage.tpEndTime = DateTime.now().millisecondsSinceEpoch;

                  // 保存最新IO序号
                  socketData.recvIONumber = recvIOData.localPackage.headInfo.ioNum;

                  // 通知接收完成
                  _cbOnRecv?.call(recvIOData.socketData, recvIOData.localPackage);

                  // 回复确认
                  if (recvIOData.localPackage.headInfo.needConfirm) {
                    _replyConfirm(socketData, recvIOData.localPackage.headInfo.ioNum);
                  }

                  // 清空接收缓存区
                  recvIOData.localPackage.clear();
                  continue;
                } else if (bufRemainSize == 0) {
                  break;
                }
                /**************************************************************************************************************************/

                // 有Package数据
                if (null == recvIOData.localPackage.package1) {
                  recvIOData.localPackage.package1Size = (recvIOData.localPackage.headInfo.size - PackageBase.classSize).toInt();
                }

                // 计算节点剩余待读取字节数
                nodeRemainWaitBytes = nodeNeedRcvBytes - nodeHasRcvBytes;
                if (nodeRemainWaitBytes > bufRemainSize) {
                  nodeRemainWaitBytes = bufRemainSize;
                }

                // 读取数据
                Uint8List readData = reader.read(nodeRemainWaitBytes);
                recvIOData.localPackage.buffer.add(readData, copy: true); // 将读取到的数据缓存

                nodeHasRcvBytes += nodeRemainWaitBytes;
                recvIOData.localPackage.receivedBytes += nodeRemainWaitBytes;
                bufRemainSize -= nodeRemainWaitBytes;

                if (nodeHasRcvBytes == nodeNeedRcvBytes) {
                  // 全部Package接收完毕
                  recvIOData.localPackage.package1 = recvIOData.localPackage.buffer.toBytes();

                  // 保存结束时间
                  recvIOData.localPackage.tpEndTime = DateTime.now().millisecondsSinceEpoch;

                  // 保存最新IO序号
                  socketData.recvIONumber = recvIOData.localPackage.headInfo.ioNum;

                  // 通知接收完成
                  _cbOnRecv?.call(recvIOData.socketData, recvIOData.localPackage);

                  // 回复确认
                  if (recvIOData.localPackage.headInfo.needConfirm) {
                    _replyConfirm(socketData, recvIOData.localPackage.headInfo.ioNum);
                  }

                  // 清空接收缓存区
                  recvIOData.localPackage.clear();
                  continue;
                } else {
                  break;
                }
              }
            }
          }
          break;
      }
    }
  }

  // socket断开连接
  void _onClose([arguments]) {
    SocketData socketData = arguments[0] as SocketData;
    disconnect(socketData, NetDisconnectCode.Exception);

    // 从已连接列表中移除
    _connectedSocketsData.remove(socketData.id);

    // 通知
    _cbOnDisconnect?.call(socketData);
  }

  void disconnect(SocketData socketData, NetDisconnectCode code) {
    socketData.close();
  }

  bool _sendList(IOData ioData, [bool priority = false]) {
    // 添加进发送列表
    if (!ioData.socketData.addSendList(ioData, priority)) {
      ioData.reset();
      return false;
    }

    if (ioData.socketData.isSending)
    {
      return true;
    }

    _onReadySend(ioData.socketData, ioData);

    return true;
  }

  Future<void> _send(IOData ioData) async {
    ioData.socketData.isSending = true;

    bool isSucceed = true;
    int nodeSendBytes = 0; // 当前节点已发送字节数
    int nodeRemainSendBytes = 0; // 当前节点剩余待发送字节数
    int currentSendBytes = SINGLE_PACKAGE_SIZE; // 当前将要发送字节数

    // 重置发送心跳时间
    ioData.socketData.tpSendHeartbeat = DateTime.now().millisecondsSinceEpoch;

    do{
      // 发送headInfo
      if (ioData.localPackage.sendBytes < PackageBase.classSize){
        ioData.localPackage.tpStartTime = ioData.socketData.tpSendHeartbeat;

        try{
          ioData.socketData.sock!.add(ioData.localPackage.headInfo.toBytes());
          await ioData.socketData.sock!.flush().then((value){
            ioData.localPackage.sendBytes = (ioData.localPackage.sendBytes + PackageBase.classSize).toInt();
          }, onError: (error){
            _log('发送PackageBase时发生错误 error:${error.toString()}');
            ioData.socketData.close();
          });
        } catch (e) {
          _log('DirectSend tcp出现异常，e=${e.toString()}');
          ioData.socketData.close();
          return;
        }
      }

      // 发送package1
      if (ioData.localPackage.package1Size > 0 && ioData.localPackage.sendBytes < PackageBase.classSize + ioData.localPackage.package1Size){
        ioData.localPackage.tpStartTime = ioData.socketData.tpSendHeartbeat;

        try{
          ioData.socketData.sock!.add(ioData.localPackage.package1!);
          await ioData.socketData.sock!.flush().then((value){
            ioData.localPackage.sendBytes += ioData.localPackage.package1Size;
          }, onError: (error){
            _log('发送package1时发生错误 error:${error.toString()}');
            ioData.socketData.close();
          });
        } catch (e) {
          _log('DirectSend tcp出现异常，e=${e.toString()}');
          ioData.socketData.close();
          return;
        }
      }

      // 发送package2
      if (ioData.localPackage.package2Size > 0 && ioData.localPackage.sendBytes < PackageBase.classSize + ioData.localPackage.package1Size + ioData.localPackage.package2Size){
        ioData.localPackage.tpStartTime = ioData.socketData.tpSendHeartbeat;

        try{
          ioData.socketData.sock!.add(ioData.localPackage.package2!);
          await ioData.socketData.sock!.flush().then((value){
            ioData.localPackage.sendBytes += ioData.localPackage.package2Size;
          }, onError: (error){
            _log('发送package2时发生错误 error:${error.toString()}');
            ioData.socketData.close();
          });
        } catch (e) {
          _log('DirectSend tcp出现异常，e=${e.toString()}');
          ioData.socketData.close();
          return;
        }
      }

      // 发送文件
      if (NetDataType.NDT_File == ioData.localPackage.headInfo.dataType
        || NetDataType.NDT_MemoryAndFile == ioData.localPackage.headInfo.dataType){
        File file = File(ioData.localPackage.filePath!);
        if(!file.existsSync()){
          _log('待发送文件不存在 filePath:${ioData.localPackage.filePath!}');

          // 从发送列表中移除头部ioData
          ioData.socketData.onSendComplete();
          break;
        }

        await ioData.socketData.sock!.addStream(file.openRead()).then((value){
          _log('文件发送完成');
          ioData.localPackage.sendBytes += ioData.localPackage.fileInfo!.fileLength;
        }, onError: (error){
          _log('发送文件时发生错误 error:${error.toString()}');
          // 从发送列表中移除头部ioData
          ioData.socketData.close();
        });
      }
    }while(false);

    _onReadySend(ioData.socketData, ioData);
  }

  void _onReadySend(SocketData socketData, IOData ioData) {
    // 检查数据是否全部发送完成
    if (ioData.localPackage.headInfo.size == ioData.localPackage.sendBytes) {
      ioData.localPackage.tpEndTime = DateTime.now().millisecondsSinceEpoch;

      // 通知
      if (ioData.localPackage.headInfo.netInfoType.index > NetInfoType.NIT_InternalMsg.index) {
        _cbOnSend?.call(socketData, ioData.localPackage);
      }

      if (ioData.isNeedConfirmRecv())
      {
        // 不再继续发送列表，清理数据、发送下一个的操作将在收到确认信息后进行
        return;
      }

      // 从发送列表中移除头部ioData
      socketData.onSendComplete();

      // 检查发送列表是否有待发送的对象
      IOData? waitSendIOData = socketData.getWaitSendIOData();
      if (null != waitSendIOData) {
        _send(waitSendIOData);
      }else{
        socketData.isSending = false;
      }
    } else {
      // 继续发送
      _send(ioData);
    }
  }

  void _replyConfirm(SocketData socketData, int ioNum) {
    var ioData = socketData.getIOData(NetAction.ACTION_SEND, NetInfoType.NIT_AutoConfirm);
    ioData.localPackage.headInfo.ioNum = ioNum;

    _sendList(ioData, true);
  }
}
