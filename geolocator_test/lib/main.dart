import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// https://pub.dev/packages/geolocator
/// https://blog.csdn.net/llssdshiyi/article/details/135523326

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '调试-定位代码'),
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
  final TextEditingController _msgController = TextEditingController(); // 接收消息文本控制器
  final ScrollController      _msgScrollController = ScrollController();
  double lonA = 6.9876543;
  double latA = 52.123456;
  double lonB = 6.9876543;
  double latB = 52.123456;
  bool isUseLonA = false;

  @override
  void initState(){
    super.initState();

    printLog('initState()');
  }

  @override
  void dispose(){
    _msgController.dispose();

    super.dispose();
  }

  void getLocationService() async{
    // 检查设备的定位服务是否打开
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      printLog("定位服务未打开");

      // 要求用户启用定位服务
      var res = await Geolocator.openLocationSettings();
      if (!res) {
        // 被拒绝
        printLog("用户拒绝打开定位服务");
        return;
      }

      // 仅打开操作系统的定位服务设置页面，启用按钮需要用户自己操作！
      printLog("已打开操作系统的定位服务设置页面");
    }

    printLog("定位服务已打开");

    // 监控定位服务状态
    StreamSubscription<ServiceStatus> serviceStatusStream = Geolocator.getServiceStatusStream().listen(
        (ServiceStatus status) {
          if(status == ServiceStatus.enabled){
            printLog("定位服务状态改变：已打开");
          }else{
            printLog("定位服务状态改变：已关闭");
          }
    });
  }

  void getLocationPermission() async{
    // 检查/获取定位权限
    LocationPermission permission = await Geolocator.checkPermission();
    printLog("定位权限  $permission");
    if (permission == LocationPermission.deniedForever) {
      printLog("定位权限被永久禁止");

      // 打开操作系统的应用程序特定设置页面，启用按钮需要用户自己操作！
      Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      printLog("开始申请定位权限");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        printLog("申请定位权限被拒绝 $permission");
        return;
      }if (permission == LocationPermission.deniedForever) {
        printLog("定位权限被永久禁止");

        // 打开操作系统的应用程序特定设置页面，启用按钮需要用户自己操作！
        Geolocator.openAppSettings();
        return;
      } else{
        printLog("申请定位权限已通过");
      }
      return;
    }
  }

  void getCurrentLocation() async{
    printLog("开始获取当前位置...");
    // 获取一次位置
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    printLog("当前位置 Lon:${position.longitude} Lat:${position.latitude}");

    // 实时获取位置
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if(position != null){
          // 缓存位置
          if(isUseLonA){
            lonA = position.longitude;
            latA = position.latitude;
          }else{
            lonB = position.longitude;
            latB = position.latitude;
          }
          isUseLonA = !isUseLonA;
        }

      printLog(position == null ? '实时位置 Unknown' : '实时位置 Lon:${position.longitude} Lat:${position.latitude}');
    });
  }

  void getDistance(){
    double distanceInMeters = Geolocator.distanceBetween(latA, lonA, latB, lonB);
    printLog("两坐标之间的距离为$distanceInMeters米");
    double bearing = Geolocator.bearingBetween(latA, lonA, latB, lonB);
    printLog("两坐标之间的方位角为$bearing");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            msgListview(),
            ElevatedButton(onPressed: getLocationService, child: Text("检测定位服务是否打开")),
            ElevatedButton(onPressed: getLocationPermission, child: Text("获取定位权限")),
            ElevatedButton(onPressed: getCurrentLocation, child: Text("获取当前位置")),
            ElevatedButton(onPressed: getDistance, child: Text("获取距离/方位角")),
          ],
        ),
      ),
    );
  }

  // 接收消息列表框
  Widget msgListview() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.black12,
      ),
      height: 300,
      child: TextField(
        readOnly: true,
        controller: _msgController,
        scrollController: _msgScrollController,
        expands: true, // 填充父窗口
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10)
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  // 打印日志
  void printLog(String log) {
    setState(() {
      log = '${DateTime.now()}\t$log';
      print(log);
      log += '\n';
      _msgController.text += log;

      if (_msgScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 30), () { // 延迟等待位置数据更新
          _msgScrollController.jumpTo(
            _msgScrollController.position.maxScrollExtent, //滚动到底部
          );
        });
      }
    });
  }
}
