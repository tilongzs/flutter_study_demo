import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Circle Animation')),
        body: CircleAnimation(),
      ),
    );
  }
}

class CircleAnimation extends StatefulWidget {
  const CircleAnimation({super.key});

  @override
  _CircleAnimationState createState() => _CircleAnimationState();
}

class _CircleAnimationState extends State<CircleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 100, end: 500).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              double delay = index * 1.67; // 调整延迟时间
              double value = (_controller.value + delay) % 1.0;
              return Opacity(
                opacity: 1 - value,
                child: Container(
                  width: 100 + 400 * value,
                  height: 100 + 400 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.lerp(Colors.pink, Colors.lightBlue, value)!,
                      width: 10,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
