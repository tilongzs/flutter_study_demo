import 'dart:ffi';
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
    final cursorPoint = allocate<POINT>();
    int isSucess = GetCursorPos(cursorPoint);
    if (isSucess != 0) {
      print('GetCursorPos success x:${cursorPoint.ref.x} y:${cursorPoint.ref.y}');

      cursorPoint.ref.x = 100;
      cursorPoint.ref.y = 100;

      _hwnd = WindowFromPoint(cursorPoint.address);
      if (_hwnd != 0) {
        print('WindowFromPoint success');
      } else {
        print('WindowFromPoint failed');
      }

    }  else {
      print('GetCursorPos failed');
    }

    free(cursorPoint);
  }

  void onBtnFindWindowEx(){
    _hwnd = FindWindowEx(0, 0, TEXT('FLUTTER_RUNNER_WIN32_WINDOW'), TEXT('desktop_windowsapi_app'));
    if (_hwnd != 0) {
      print('FindWindowEx success');
    } else {
      print('FindWindowEx failed');
    }
  }

  void onBtnMoveWIndow(){
    if (_hwnd != 0) {
      MoveWindow(_hwnd, 100, 100, 200, 200, 1);
    }  else {
      print('_hwnd == 0');
    }
  }

  void onBtnCenterWindow(){
    if (_hwnd != 0) {
      // 获取屏幕尺寸
      int scrWidth = GetSystemMetrics(0); // SM_CXSCREEN
      int scrHeight = GetSystemMetrics(1);  // SM_CYSCREEN

      // 获取窗体尺寸
      final rect = allocate<RECT>();
      GetClientRect(_hwnd, rect);
      int width = rect.ref.right - rect.ref.left;
      int height = rect.ref.bottom - rect.ref.top;

      // 计算居中位置
      int left = ((scrWidth - width) / 2).toInt();
      int top = ((scrHeight - height) / 2).toInt();

      // 设置窗体位置 （居中显示）
      MoveWindow(_hwnd, left, top, width, height,  1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App'),
      ),
      body: Center(
        child: Wrap(
          spacing: 10,
          children: [
            ElevatedButton(onPressed: onBtnWindowFromPoint, child: Text('WindowFromPoint')),
            ElevatedButton(onPressed: onBtnFindWindowEx, child: Text('FindWindowEx')),
            ElevatedButton(onPressed: onBtnMoveWIndow, child: Text('MoveWindow')),
            ElevatedButton(onPressed: onBtnCenterWindow, child: Text('窗口居中')),
            ElevatedButton(onPressed: onBtnCloseWindow, child: Text('CloseWindow')),
            ElevatedButton(onPressed: onBtnPostQuitMessage, child: Text('PostQuitMessage')),
            ElevatedButton(onPressed: onBtnKnownFolder, child: Text('获取系统文件夹路径')),
          ],
        ),
      ),
    );
  }
}