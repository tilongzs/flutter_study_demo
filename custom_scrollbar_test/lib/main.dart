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

class _HomePageState extends State<HomePage> {
  final List<String> _recvMsg = []; // 接收到的消息
  double _alignmentY = -1; // 范围-1~1
  double _maxScrollExtent = 0;
  int _lineNum = 0;
  final ScrollController _listViewScrollController = ScrollController();
  final ScrollController _textFieldScrollController = ScrollController();
  final TextEditingController _textFieldController = TextEditingController();

  // 模拟增加一行数据
  void addLine(){
    _lineNum++;
    _recvMsg.add(_lineNum.toString());
    _textFieldController.text += (_lineNum.toString() + '\n');

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
      _textFieldController.text += (_lineNum.toString() + '\n');
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
            Text('ListView示例'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
                color: Colors.black12,
              ),
              height: 300,
              child: listViewExample(), // ListView示例
              ),
            Text('TextField示例'), // TextField示例
            recvMsgListview()
          ],
        ),
      ),
    );
  }

  Widget listViewExample() {
    return AdaptiveScrollbar(
      controller: _listViewScrollController,
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
          controller: _listViewScrollController,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return Center(child: Text(_recvMsg[index]));
          },
          itemCount: _recvMsg.length,
        ),
      ),
    );
  }

  Widget recvMsgListview() {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black12,
      ),
      width: 400,
      height: 200,
      child: AdaptiveScrollbar(
        controller: _textFieldScrollController,
        sliderDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        sliderActiveDecoration: BoxDecoration(
            color: Color.fromRGBO(206, 206, 206, 100),
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        underColor: Colors.black12,
        position: ScrollbarPosition.right,
        sliderChild: Center(child: Icon(Icons.drag_indicator, size: 12,) ),

        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // 无效，无法隐藏默认滚动条
          child: TextField(
            readOnly: true,
            controller: _textFieldController,
            scrollController:_textFieldScrollController,
            expands: true, // 填充父窗口
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 10)
            ),
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
      ),
    );
  }
}
