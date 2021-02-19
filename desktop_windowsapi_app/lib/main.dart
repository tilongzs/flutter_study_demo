import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/material.dart';
import 'knownfolder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title :'App',
      initialRoute: '/',
      routes: {
        '/':(context)=>HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>{
  int _hwnd = 0;

  @override
  void initState() {
    super.initState();

    onBtnFindWindowEx();
  }

  void onBtnWindowFromPoint(){
    Pointer<POINT> cursorPoint = calloc<POINT>();
    int isSucess = GetCursorPos(cursorPoint);
    if (isSucess != 0) {
      print('GetCursorPos success x:${cursorPoint.ref.x} y:${cursorPoint.ref.y}');

      // 测试手动修改光标位置
      cursorPoint.ref.x = 100;
      cursorPoint.ref.y = 100;

      _hwnd = WindowFromPoint(cursorPoint.ref);
      if (_hwnd != 0) {
        print('WindowFromPoint success');
      } else {
        print('WindowFromPoint failed');
      }

    }  else {
      print('GetCursorPos failed');
    }

    calloc.free(cursorPoint);
  }

  void onBtnFindWindowEx(){
    _hwnd = FindWindowEx(0, 0, TEXT('FLUTTER_RUNNER_WIN32_WINDOW'), TEXT('desktop_windowsapi_app'));
    if (_hwnd != 0) {
      print('FindWindowEx success');
    } else {
      print('FindWindowEx failed');
    }
  }

  void onBtnMoveWindow(){
    if (_hwnd != 0) {
      // 当前版本修改窗口大小会导致窗口无响应！需要进一步测试验证
      MoveWindow(_hwnd, 100, 100, 600, 400, 1);
    }  else {
      print('_hwnd == 0');
    }
  }

  void onBtnCenterWindow(){
    if (_hwnd != 0) {
      // 获取屏幕尺寸
      int scrWidth = GetSystemMetrics(0); // SM_CXSCREEN
      int scrHeight = GetSystemMetrics(1);  // SM_CYSCREEN

      // 获取窗体客户区尺寸（客户区尺寸小于窗口尺寸）
      final rect = calloc<RECT>();
      GetClientRect(_hwnd, rect);
      int width = rect.ref.right - rect.ref.left;
      int height = rect.ref.bottom - rect.ref.top;

      // 计算居中位置
      int left = ((scrWidth - width) / 2).toInt();
      int top = ((scrHeight - height) / 2).toInt();

      // 设置窗体位置 （居中显示）
    //  MoveWindow(_hwnd, left, top, width, height,  1);
      SetWindowPos(_hwnd, 0, left, top, 0, 0, 1 | 4/*SWP_NOSIZE | SWP_NOZORDER*/);
    }  else {
      print('_hwnd == 0');
    }
  }

  void onBtnCloseWindow(){
    if (_hwnd != 0) {
      // 仅仅关闭窗口，Flutter桌面进程仍在运行，因此不能用来关闭Flutter桌面进程！
      // SendMessage(_hwnd, WM_CLOSE, 0, 0);
    }  else {
      print('_hwnd == 0');
    }
  }

  // 最小化窗口
  void minWindow(){
    ShowWindow(_hwnd, SW_MINIMIZE);
  }

  // 最大化窗口
  void maxWindow(){
    ShowWindow(_hwnd, SW_MAXIMIZE);
  }

  void onBtnPostQuitMessage(){
    // 在这里没什么卵用，并不能用来关闭Flutter桌面进程！
    PostQuitMessage(0);

    // 还是用Flutter的exit()管用
    // exit(0);
  }

  void onBtnKnownFolder() {
    print('Temporary path is ${getTemporaryPath()}');
    print('SHGetFolderPath returned ${getFolderPath()}');
    print('SHGetKnownFolderPath returned ${getKnownFolderPath()}');
  }

  void onBtnNoframe(){
    if (_hwnd != 0) {
      // 仅仅关闭窗口，Flutter桌面进程仍在运行，因此不能用来关闭Flutter桌面进程！
      // SendMessage(_hwnd, WM_CLOSE, 0, 0);
    }  else {
      print('_hwnd == 0');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App'),
      ),
      body: Column(
        children: [
          titleRect(),
          buttonsRect()
        ],
      ),
    );
  }

  Widget titleRect(){
    return Flexible(child: Container(
      height: 40,
      color: Colors.black12,
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 5,
        children: [
          IconButton(onPressed: minWindow, icon: Icon(Icons.minimize),),
          IconButton(onPressed: maxWindow, icon: Icon(Icons.web_asset_sharp),),
          CloseButton(onPressed: ()=>exit(0))
        ],
      ),
    ));
  }

  Widget buttonsRect(){
    return Expanded(child: Container(
      child: Wrap(
        spacing: 10,
        children: [
          ElevatedButton(onPressed: onBtnWindowFromPoint, child: Text('WindowFromPoint')),
          ElevatedButton(onPressed: onBtnFindWindowEx, child: Text('FindWindowEx')),
          ElevatedButton(onPressed: onBtnMoveWindow, child: Text('MoveWindow')),
          ElevatedButton(onPressed: onBtnCenterWindow, child: Text('窗口居中(SetWindowPos)')),
          ElevatedButton(onPressed: onBtnCloseWindow, child: Text('CloseWindow')),
          ElevatedButton(onPressed: onBtnPostQuitMessage, child: Text('PostQuitMessage')),
          ElevatedButton(onPressed: onBtnKnownFolder, child: Text('获取系统文件夹路径')),
          ElevatedButton(onPressed: onBtnNoframe, child: Text('窗口无边框')),
        ],
      ),
    ));
  }
}