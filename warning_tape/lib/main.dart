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
  double _stripeWidth = 20.0;
  final Color yellowColor = Colors.yellow;
  final Color blackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  // 弧度转角度
  double radianToAngle(double radian) {
    return radian * 180 / (math.pi);
  }

  // 角度转弧度
  double angleToRadian(double angle) {
    return angle * math.pi / 180;
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        _offset -= 1.0; // 控制移动速度
        if (_offset <= -_stripeWidth * 2) {
          _offset = 0.0;
        }
        _startAnimation();
      });
    });
  }

  Widget generateTape(double borderWidth, double borderHeight,
      double stripeWidth, double angle) {
    angle = angle.clamp(1, 80);

    _stripeWidth = stripeWidth;
    double rectWidth = borderHeight / math.cos(angleToRadian(angle));
    double rectHeight = borderHeight / math.sin(angleToRadian(angle));

    return Container(
      width: borderWidth,
      height: borderHeight,
      color: blackColor,
      child: Stack(
        children: List.generate(
          (borderWidth / _stripeWidth + 3).toInt(), // 无数个条纹
          (index) {
            final leftOffset = index * _stripeWidth + _offset;
            return Positioned(
              left: leftOffset,
              top: -math.cos(angleToRadian(angle)) * _stripeWidth, // 裁剪掉顶部
              child: Transform.rotate(
                angle: angleToRadian(angle), // 角度转弧度
                child: Container(
                  width: rectWidth,
                  height: rectHeight,
                  color: index.isEven ? yellowColor : blackColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: generateTape(200, 30, 20, 30));
  }
}
