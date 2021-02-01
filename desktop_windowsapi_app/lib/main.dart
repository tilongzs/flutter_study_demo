import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/material.dart';
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
    //Pointer<POINT> cursorPoint = Pointer<POINT>.fromAddress(0);
    final cursorPoint = POINT.allocate();
    int isSucess = GetCursorPos(cursorPoint.addressOf);
    if (isSucess != 0) {
      print('GetCursorPos success');

      POINT a = POINT.allocate();
      a.x = 100;
      a.y = 100;
      //   int hwnd = WindowFromPoint(cursorPoint.addressOf.address);
      _hwnd = WindowFromPoint(a.addressOf.address);
      if (_hwnd != 0) {
        print('WindowFromPoint success');
      } else {
        print('WindowFromPoint failed');
      }

    }  else {
      print('GetCursorPos failed');
    }

    free(cursorPoint.addressOf);
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

  void onBtnCloseWindow(){
    if (_hwnd != 0) {
      // 仅仅关闭窗口，Flutter桌面进程仍在运行，因此不能用来关闭Flutter桌面进程！
      SendMessage(_hwnd,  WM_CLOSE, 0, 0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App'),
      ),
      body: Center(
        child: Wrap(
          direction: Axis.vertical,
          spacing: 10,
          children: [
            ElevatedButton(onPressed: onBtnWindowFromPoint, child: Text('nWindowFromPoint')),
            ElevatedButton(onPressed: onBtnFindWindowEx, child: Text('FindWindowEx')),
            ElevatedButton(onPressed: onBtnMoveWIndow, child: Text('MoveWindow')),
            ElevatedButton(onPressed: onBtnCloseWindow, child: Text('CloseWindow')),
            ElevatedButton(onPressed: onBtnPostQuitMessage, child: Text('PostQuitMessage')),
          ],
        ),
      ),
    );
  }
}