import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('黄黑相间的倾斜条纹')),
        body: MovingWarningStripe(),
      ),
    );
  }
}

class MovingWarningStripe extends StatefulWidget {
  @override
  _MovingWarningStripeState createState() => _MovingWarningStripeState();
}

class _MovingWarningStripeState extends State<MovingWarningStripe> {
  double _offset = 0.0;
  final double stripeWidth = 20.0;
  final double stripeHeight = 30.0;
  final Color yellowColor = Colors.yellow;
  final Color blackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _offset -= 1.0; // 控制移动速度
        if (_offset <= -stripeWidth*2) {
          _offset = 0.0;
        }
        _startAnimation();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 30,
        color: Colors.black,
        child: Stack(
          children: List.generate(
            30, // 无数个条纹
                (index) {
              final leftOffset = index * stripeWidth + _offset;
              return Positioned(
                left: leftOffset,
                top: -math.sin(45) * stripeWidth, // 裁剪掉顶部
                child: Transform.rotate(
                  angle: math.pi / 4, // 45°的弧度
                  child: Container(
                    width: stripeWidth,
                    height: stripeHeight * math.sin(45) * 4,
                    color: index.isEven ? yellowColor : blackColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
