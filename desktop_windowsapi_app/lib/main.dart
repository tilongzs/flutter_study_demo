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
  Pointer<POINT> _drawgBeginCursorPoint;  // 拖动窗口的起始光标位置
  Pointer<POINT> _drawgCursorPoint;  // 拖动窗口的实时光标位置
  Pointer<RECT> _dragBeginRect; // 拖动窗口的起始窗口位置

  @override
  void initState() {
    super.initState();

    _drawgBeginCursorPoint = calloc<POINT>();
    _drawgCursorPoint = calloc<POINT>();
    _dragBeginRect = calloc<RECT>();
    onBtnFindWindowEx();
  }

  @override
  void dispose() {
    calloc.free(_drawgBeginCursorPoint);
    calloc.free(_drawgCursorPoint);
    calloc.free(_dragBeginRect);
    super.dispose();
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
      SetWindowLongPtr(_hwnd, -16/*GWL_STYLE*/, WS_CLIPCHILDREN | WS_POPUP | WS_VISIBLE);
    }  else {
      print('_hwnd == 0');
    }
  }

  void onBtnLoadTestDll(){
    final dllTest = DynamicLibrary.open('DllTest.dll');
    if (dllTest != null) {
      final Substract = dllTest.lookupFunction<
          Int32 Function(Int32 a, Int32 b),
          int Function(int a, int b)>('Substract');

      if (Substract != null) {
        print('查找Substract函数成功 500-400:${Substract(500, 400)}');
      }else{
        print('查找Substract函数失败');
      }
    } else {
      print('加载DllTest.dll失败');
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
          dragMoveWindowRect(),
          ElevatedButton(onPressed: onBtnWindowFromPoint, child: Text('WindowFromPoint')),
          ElevatedButton(onPressed: onBtnFindWindowEx, child: Text('FindWindowEx')),
          ElevatedButton(onPressed: onBtnMoveWindow, child: Text('MoveWindow')),
          ElevatedButton(onPressed: onBtnCenterWindow, child: Text('窗口居中(SetWindowPos)')),
          ElevatedButton(onPressed: onBtnCloseWindow, child: Text('CloseWindow')),
          ElevatedButton(onPressed: onBtnPostQuitMessage, child: Text('PostQuitMessage')),
          ElevatedButton(onPressed: onBtnKnownFolder, child: Text('获取系统文件夹路径')),
          ElevatedButton(onPressed: onBtnNoframe, child: Text('窗口无边框')),
          ElevatedButton(onPressed: onBtnLoadTestDll, child: Text('加载自定义dll')),
        ],
      ),
    ));
  }

  // 鼠标拖动移动窗口
  Widget dragMoveWindowRect(){
    return GestureDetector(
      child: Container(
        width: 150,
        height: 40,
        alignment: Alignment.center,
        color: Colors.yellow,
        child: Text('鼠标按下拖动窗口'),
      ),
      onHorizontalDragStart: (DragStartDetails details){
        int isSucess = GetCursorPos(_drawgBeginCursorPoint);
        if (isSucess != 0) {
          print('_drawgBeginCursorPoint:${_drawgBeginCursorPoint.ref.x},${_drawgBeginCursorPoint.ref.y}');
        }

        if (_hwnd != 0) {
          GetWindowRect(_hwnd, _dragBeginRect);
          print('_dragBeginRect:${_dragBeginRect.ref.left},${_dragBeginRect.ref.top},${_dragBeginRect.ref.right},${_dragBeginRect.ref.bottom}');
        }

        //print('onHorizontalDragStart: globalPosition:${details.globalPosition} localPosition:${details.localPosition}');
      },
      onHorizontalDragUpdate: (DragUpdateDetails details){
        if (_hwnd != 0) {
          GetCursorPos(_drawgCursorPoint);
          int newLeft = _dragBeginRect.ref.left + _drawgCursorPoint.ref.x - _drawgBeginCursorPoint.ref.x;
          int newTop = _dragBeginRect.ref.top + _drawgCursorPoint.ref.y - _drawgBeginCursorPoint.ref.y;
          SetWindowPos(_hwnd, 0, newLeft.toInt(), newTop.toInt(), 0, 0, 1 | 4/*SWP_NOSIZE | SWP_NOZORDER*/);
          print('newLeft:$newLeft, newTop:$newTop');
        }
        //print('DragUpdateDetails: globalPosition:${details.globalPosition} localPosition:${details.localPosition}');
      },
      onHorizontalDragEnd:  (DragEndDetails details){
        print('onHorizontalDragEnd');
      },
    );
  }
}