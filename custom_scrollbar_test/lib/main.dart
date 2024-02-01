import 'package:flutter/material.dart';
import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';

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

class _ScrollBar extends StatelessWidget {
  double _viewHeight = 0;
  double _parentHeight = 0;

  _ScrollBar(double viewHeight, double parentHeight){
    _viewHeight = viewHeight;
    _parentHeight = parentHeight;
  }

  double calculateHeight(){
    if (_viewHeight == 0 || _viewHeight == _parentHeight) {
      return 0;
    }  else {
      double height = _parentHeight * _parentHeight / _viewHeight;
      return height < 50 ? 50 : height; // 限制最小值
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: calculateHeight(),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.blue),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.arrow_drop_up,
            size: 18,
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final List<String> _recvMsg = []; // 接收到的消息
  double _alignmentY = -1; // 范围-1~1
  double _maxScrollExtent = 0;
  final _listHeight = 300.0;
  int _lineNum = 0;
  final ScrollController verticalScrollController = ScrollController();

  void addLine(){
    _lineNum++;
    _recvMsg.add(_lineNum.toString());
    setState(() {

    });
  }

  @override
  void initState() {
    super.initState();

    // test
    while(_lineNum < 30){
      _lineNum++;
      _recvMsg.add(_lineNum.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text('Custom Scrollbar'),
      ),
       floatingActionButton: FloatingActionButton(
         child: const Icon(Icons.add),
         onPressed: () => setState(() {
           addLine();
         }),
       ),
      body: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
                color: Colors.black12,
              ),
              height: _listHeight,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  msgListview(), // 消息列表
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 展示接收到的消息Listview
  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    print('滚动组件最大滚动距离:${metrics.maxScrollExtent}');
    print('当前滚动位置:${metrics.pixels}');

    _maxScrollExtent = metrics.maxScrollExtent == double.infinity ? 0 : metrics.maxScrollExtent;
    _alignmentY = metrics.maxScrollExtent == 0 ? -1 : -1 + (metrics.pixels / metrics.maxScrollExtent) * 2;
    print('_alignmentY:$_alignmentY');

    setState(() {

    });
    return true;
  }

  Widget msgListview() {
    return AdaptiveScrollbar(
      controller: verticalScrollController,
      sliderDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
      sliderActiveDecoration: BoxDecoration(
          color: Color.fromRGBO(206, 206, 206, 100),
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
      underColor: Colors.yellow,
      position: ScrollbarPosition.right,
      sliderChild: Center(child: Icon(Icons.drag_indicator, size: 12,) ),

      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // 隐藏默认滚动条
        child: ListView.builder(
          controller: verticalScrollController,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return Center(child: Text(_recvMsg[index]));
          },
          itemCount: _recvMsg.length,
        ),
      ),
    );
  }
/**********************************************************************/
}
