import 'dart:collection';
import 'dart:typed_data' show Endian, Uint8List;
import 'dart:io';
import 'package:buffer/buffer.dart';
import 'signal.dart';

const MaxWaitSendIOs = 100;
const SINGLE_PACKAGE_SIZE = 65000;	// 发送单个包的最大大小（理论值：65507字节）
const NET_BUFFER_LEN = 8192;		// 单个Buffer长度
const MAX_NET_PACKAGE_SIZE = 10485760; // 单次传输非文件类型的最大大小（10M）

enum NetInfoType {
  NIT_NULL,	// 用于初始化
  NIT_Heartbeat,		// 心跳
  NIT_AutoConfirm,	// 自动回复确认

  NIT_InternalMsg,
  // 上面的内部程序数据一般不与通知
  /***********************************************/

  // 以下为业务演示用
  NIT_Message,
  NIT_File,
}

enum NetAction {
  ACTION_NULL,		// 用于初始化

  ACTION_DISCONNECT,
  ACTION_ACCEPT,
  ACTION_CONNECT,
  ACTION_SEND,
  ACTION_RECV,
}

// 网络断开连接原因代码
enum NetDisconnectCode {
  Unknown,		// 未知
  Exception,		// 异常
  ExistingConnection,		// 连接已存在
  HeadinfoError,		// 头信息错误
  CreateWriteFileError,		// 创建写文件句柄错误
}

// 网络数据类型
enum NetDataType {
  NDT_Memory,	// 内存数据
  NDT_File,	// 文件数据
  NDT_MemoryAndFile	// 内存+文件数据
}

// 通信身份
enum NetIdentity {
  NID_PublicGroup,	// 公共组
  NID_PrivateGroup,	// 私有组
  NID_Member			// 私有组成员
}

// socket用途
enum SocketPurpose {
  SP_Msg,		// 传递消息
  SP_File		// 传递文件
}

// 网络包基本信息
class PackageBase {
  int		ioNum = 0;  // （uint32_t）
  NetDataType	dataType = NetDataType.NDT_Memory;		// 网络数据类型（int）
  bool	needConfirm = false;	// 需要回复确认
  NetInfoType		netInfoType = NetInfoType.NIT_NULL;	// 网络信息类型（int）
  int	  size = PackageBase.classSize;	// 长度（字节、包含自身）（uint64_t）

  PackageBase() {
    reset();
  }

  void reset() {
    ioNum = 0;
    dataType = NetDataType.NDT_Memory;
    needConfirm = false;
    netInfoType = NetInfoType.NIT_NULL;
    size = PackageBase.classSize;
  }

  Uint8List toBytes(){
    var bufWriter = ByteDataWriter (endian: Endian.little);
    bufWriter.writeUint32(ioNum);
    bufWriter.writeInt32(dataType.index);
    bufWriter.writeInt8(needConfirm ? 1 : 0);
    bufWriter.writeInt32(netInfoType.index);
    bufWriter.writeUint64(size);
    return bufWriter.toBytes();
  }

  static PackageBase? fromBytes(Uint8List data){
    var bufReader = ByteDataReader(endian: Endian.little);
    bufReader.add(data);
    PackageBase? value = PackageBase();
    try{
      value.ioNum = bufReader.readUint32();
      value.dataType = NetDataType.values[bufReader.readInt32()];
      value.needConfirm = bufReader.readInt8() != 0;
      value.netInfoType = NetInfoType.values[bufReader.readInt32()];
      value.size = bufReader.readUint64();
    }catch(e){
      value = null;
    }

    return value;
  }

  static get classSize => 21;    // 网络字节大小
}

// 已接收的字节数 NIT_ReceivedBytes
class PackageReceivedBytes {
  int		netInfoType = 0;	// 自定义业务网络信息类型
  int   size = 0;	// 字节数
  bool	isComplete = false;	// 是否完成
}

// 文件信息
class FileInfo {
  int fileLength = 0; // uint64_t
  Uint8List fileName = Uint8List(260);

  Uint8List toBytes(){
    var bufWriter = ByteDataWriter (endian: Endian.little);
    bufWriter.writeInt64(fileLength);
    bufWriter.write(fileName);
    return bufWriter.toBytes();
  }

  static FileInfo? fromBytes(Uint8List data){
    try{
      var bufReader = ByteDataReader(endian: Endian.little);
      bufReader.add(data);
      var fileInfo = FileInfo();
      fileInfo.fileLength = bufReader.readUint64();
      fileInfo.fileName = bufReader.read(260, copy: true);
      return fileInfo;
    }catch(e){
      return null;
    }
  }

  static get classSize => 268;   // 网络字节大小
}

class PackageLocalFile {
  late FileInfo fileinfo;
  String path = '';
}

class PackageInfo {
  PackageBase headInfo = PackageBase();
  BytesBuffer buffer = BytesBuffer();
  Uint8List? package1 = null;
  Uint8List? package2 = null;

  void deletePackage()
  {
    buffer = BytesBuffer();
    package1 = null;
    package2 = null;
  }
}

class LocalPackage extends PackageInfo {
  LocalPackage();

  void clear(){
    deletePackage();

    headInfo.reset();
    sendBytes = 0;
    receivedBytes = 0;
    tpStartTime = 0;
    tpEndTime = 0;
    fileInfo = null;
    filePath = null;
    package1Size = 0;
  }

  int sendBytes = 0; // 已发送字节数
  int receivedBytes = 0;	// 已接收字节数
  int tpStartTime = 0;	// 传输的开始时间
  int tpEndTime = 0;		// 传输的结束时间

  FileInfo? fileInfo;
  String? filePath;
  int package1Size = 0;
  int package2Size = 0;
}

class IOData {
  IOData(SocketData socketData){
    this.socketData = socketData;
  }

  NetAction		action = NetAction.ACTION_NULL;
  late SocketData	socketData;

  int			      confirmTimeout = 1000;	// 自动确认的超时时长（毫秒）
  LocalPackage	localPackage = LocalPackage();

  void reset({NetAction newAction = NetAction.ACTION_NULL}){
    if (action == NetAction.ACTION_RECV && localPackage.filePath != null && (localPackage.tpEndTime != 0)) {
      // todo
      // DeleteFile(localPackage.filePath); // 删除未接收完成的临时文件
    }

    localPackage.clear();
    action = newAction;
  }

  void deleteBuf(){
    if (action == NetAction.ACTION_RECV && localPackage.filePath != null && (localPackage.tpEndTime != 0)) {
      // todo
      // DeleteFile(localPackage.filePath); // 删除未接收完成的临时文件
    }

    localPackage.clear();
    action = NetAction.ACTION_NULL;
  }

  // 每一条数据需要对方回复收到确认；默认不需要；一般仅用于非文件类型
  void setNeedConfirmRecv(){
    localPackage.headInfo.needConfirm = true;
  }

  bool isNeedConfirmRecv() => localPackage.headInfo.needConfirm;

  bool isConfirmRecvTimeout(int curTickcount){
    if (!localPackage.headInfo.needConfirm)
    {
      return false;
    }

    if (localPackage.headInfo.dataType != NetDataType.NDT_Memory)
    {
      return false;
    }

    if (0 == localPackage.tpStartTime)
    {
      return false;
    }

    return curTickcount - localPackage.tpStartTime > confirmTimeout;
  }

  int getIONumber() => localPackage.headInfo.ioNum;
}

class SocketData {
  RawSocket?    sock;

  String    remoteIP = '';			// 远程地址
  int       remotePort = 0;     // 远程端口
  int		  	id = 0;
  SocketPurpose purpose = SocketPurpose.SP_Msg;		// socket用途

  Signal    signalOnData = Signal();
  Signal    signalOnClose = Signal();
  Signal    signalOnLog = Signal();

  List<IOData>	ios = List<IOData>.empty(growable: true);		// 所有IO
  IOData?			_recvIOData;	// 当前负责接收数据的IOData；同时最多只存在一个。

  bool		_isConnected = false;
  bool		isSending = false;		// 正在发送数据
  int			sameTypeCount = 0;	// 相同数据类型的计数
  ListQueue<IOData>	waitSendIOs = ListQueue<IOData>();	// 待发送IO数据列表

  int			recvIONumber = 0;	// 最新的已接收IO序号
  int			sendIONumDistributor = 0;	// 数字标记分配器（发送IO）
  int			tpSendHeartbeat = 0;	// 心跳时间（发送）
  int			tpSendReceivedBytes = 0;	// 上次发送“已接收字节数”的时间

  int			_tpHeartbeatRecv = 0;	// 心跳时间（接收）
  static int	SocketIDistributor = 0; // SocketID分配器

  SocketData(){
    id = SocketIDistributor++;
  }

  IOData? getFreeIOData(NetAction action){
    for (var iter in ios) {
      if (iter.action == NetAction.ACTION_NULL) {
        iter.action = action;

        if (action == NetAction.ACTION_SEND) {
          sendIONumDistributor++;
          iter.localPackage.headInfo.ioNum = sendIONumDistributor;
          return iter;
        }
      }
    }

    return null;
  }

  IOData createNewIOData(NetAction action){
    var ioData = IOData(this);
    ioData.action = action;

    if (action == NetAction.ACTION_SEND) {
      sendIONumDistributor++;
      ioData.localPackage.headInfo.ioNum = sendIONumDistributor;
    }

    ios.add(ioData);

    return ioData;
  }

  IOData getIOData(NetAction action, NetInfoType netInfoType, {Uint8List? data, FileInfo? fileInfo, String? filePath}){
    IOData? ioData = getFreeIOData(action);
    ioData = ioData ?? createNewIOData(action);
    ioData.localPackage.headInfo.netInfoType = netInfoType;

    if (fileInfo != null) {
      // 附带文件
      ioData.localPackage.fileInfo = fileInfo;
      ioData.localPackage.package1 = fileInfo.toBytes();
      ioData.localPackage.package1Size = FileInfo.classSize;
      ioData.localPackage.filePath = filePath!;

      if (data != null) {
        // 附带文件+数据
        ioData.localPackage.headInfo.dataType = NetDataType.NDT_MemoryAndFile;
        ioData.localPackage.package2 = data;
        ioData.localPackage.package2Size = data.lengthInBytes;
        ioData.localPackage.headInfo.size = PackageBase.classSize + ioData.localPackage.package1Size + ioData.localPackage.package2Size + fileInfo.fileLength;
      }else{
        ioData.localPackage.headInfo.dataType = NetDataType.NDT_File;
        ioData.localPackage.headInfo.size = PackageBase.classSize + ioData.localPackage.package1Size + fileInfo.fileLength;
      }
    }else if (data != null){
      // 附带数据
      ioData.localPackage.headInfo.dataType = NetDataType.NDT_Memory;
      ioData.localPackage.package1 = data;
      ioData.localPackage.package1Size = data.lengthInBytes;
      ioData.localPackage.headInfo.size = PackageBase.classSize +  ioData.localPackage.package1Size;
    }

    return ioData;
  }

  void removeIOData(IOData ioData){
    for (var iter in ios) {
      if (iter == ioData) {
        ios.remove(iter);
        break;
      }
    }
  }

  // 检查回复确认超时
  IOData? checkConfirmTimeout(){
    if (!_isConnected) {
      return null;
    }

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (waitSendIOs.isNotEmpty) {
      if (waitSendIOs.first.isConfirmRecvTimeout(currentTime)) {
        return waitSendIOs.first;
      }
    }

    return null;
  }

  // 检查接收对方的心跳超时
  bool isHeartbeatTimeout(int currentTime, int heartbeatTimeoutMilliseconds){
    if (!_isConnected)
    {
      return false;
    }

    if (0 == heartbeatTimeoutMilliseconds)
    {
      return false;
    }

    if (currentTime - _tpHeartbeatRecv > heartbeatTimeoutMilliseconds)
    {
      return true;
    }
    else
    {
      return false;
    }
  }

  // 增加至发送列表
  bool addSendList(IOData ioData, [bool priority = false]){
    if (purpose != SocketPurpose.SP_File) {
      if (waitSendIOs.length > MaxWaitSendIOs)
      {
        return false; // 检查等待发送的列表长度，防止非文件类型的列表过长
      }
    }

    // 自动排除超过 5 个重复类型的数据
    if (waitSendIOs.length > 1) {
      // 第一个为当前正在发送的数据
      sameTypeCount = 0;
      for (var iter in waitSendIOs ) {
        if (iter.localPackage.headInfo.netInfoType == ioData.localPackage.headInfo.netInfoType) {
          sameTypeCount++;

          if (sameTypeCount == 5) {
            iter.reset();
            waitSendIOs.remove(iter);
            break;
          }
        }
      }
    }

    if(priority){
      waitSendIOs.addFirst(ioData);
    }else{
      waitSendIOs.addLast(ioData);
    }

    return true;
  }

  // 获取下一个待发送IOData
  IOData? getWaitSendIOData(){
      if (waitSendIOs.isEmpty) {
        return null;
      } else {
        return waitSendIOs.first;
      }
  }

  void onSendComplete(){
    if (waitSendIOs.isNotEmpty) {
      waitSendIOs.removeFirst();
    }  
    
    isSending = false;
  }

  // 用于“已连接”socketData接收数据
  IOData getRecvIOData(){
    if (_recvIOData == null) {
      _recvIOData = createNewIOData(NetAction.ACTION_RECV);
    }

    return _recvIOData!;
  }

  void resetRecvIOData(){
    _recvIOData?.reset();
  }

  void setConnected(bool isConn){
    _isConnected = isConn;
    if (_isConnected) {
      // 心跳开始计时
      _tpHeartbeatRecv = DateTime.now().millisecondsSinceEpoch;
    }
  }

  get isConnected => _isConnected;

  void resetHeartbeatRecv(int milliseconds){
    if (milliseconds > _tpHeartbeatRecv){
      _tpHeartbeatRecv = milliseconds;
    }
  }

  void close(){
    sock?.close();

    setConnected(false);
  }

  void onData(RawSocketEvent socketEvent){
    signalOnData.dispatch([this, socketEvent]);
  }

  void onError(Object error) {
    signalOnLog.dispatch(["SocketData::连接发送错误 error:${error.toString()}"]);
    sock?.close();
  }

  void onClose(){
    signalOnLog.dispatch(["SocketData::连接已关闭"]);
    signalOnClose.dispatch([this]);

    setConnected(false);
  }
}
/* SocketData******************************************************************/