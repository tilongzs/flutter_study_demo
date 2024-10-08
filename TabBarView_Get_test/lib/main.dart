import 'package:flutter/material.dart';
import 'package:get/get.dart';
class TabPage extends StatelessWidget {
  final int index;

  TabPage({required this.index});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: Get.nestedKey(index),
      onGenerateRoute: (settings) {
        return GetPageRoute(
          page: () => TabContent(index: index),
          settings: settings,
        );
      },
    );
  }
}

class TabContent extends StatelessWidget {
  final int index;

  TabContent({required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tab $index')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.to(()=>SubPage(index: index), id: index);
          },
          child: Text('Go to SubPage of Tab $index'),
        ),
      ),
    );
  }
}

class SubPage extends StatelessWidget {
  final int index;

  SubPage({required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SubPage of Tab $index')),
      body: Center(
        child: Text('This is SubPage of Tab $index'),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Tab 1'),
              Tab(text: 'Tab 2'),
              Tab(text: 'Tab 3'),
              Tab(text: 'Tab 4'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TabPage(index: 1),
            TabPage(index: 2),
            TabPage(index: 3),
            TabPage(index: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // 退出登录，返回登录页面
            Get.offAll(()=>LoginPage());
          },
          child: Icon(Icons.logout),
        ),
      ),
    );
  }
}

class LoginPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login 2')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 跳转首页
            Get.offAll(()=>HomePage());
          },
          child: Text('HomePage'),
        ),
      ),
    );
  }

}
class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 假设登录成功
                Get.to(()=>LoginPage2());
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: LoginPage()
    );
  }
}
