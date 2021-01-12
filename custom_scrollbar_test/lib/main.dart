import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 60,
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

  @override
  void initState() {
    super.initState();

    // test
    for (int i = 0; i < 100; ++i) {
      _recvMsg.add(i.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Scrollbar'),
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
              height: 300,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  MsgListview(), // 消息列表
                  Container(
                    // 滚动条
                    alignment: Alignment(1, _alignmentY),
                    padding: EdgeInsets.only(right: 5),
                    child: _ScrollBar(),
                  )
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

    _alignmentY = -1 + (metrics.pixels / metrics.maxScrollExtent) * 2;
    print('_alignmentY:$_alignmentY');

    setState(() {

    });
    return true;
  }

  Widget MsgListview() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Text(_recvMsg[index]);
        },
        itemCount: _recvMsg.length,
      ),
    );
  }
/**********************************************************************/
}
