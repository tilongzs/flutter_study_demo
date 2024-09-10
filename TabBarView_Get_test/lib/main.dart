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
        if (settings.name == '/') {
          return GetPageRoute(
            page: () => TabContent(index: index),
            settings: settings,
          );
        } else if (settings.name == '/subpage') {
          return GetPageRoute(
            page: () => SubPage(index: index),
            settings: settings,
          );
        }
        return null;
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
            Get.toNamed('/subpage', id: index);
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
            Get.offAllNamed('/login');
          },
          child: Icon(Icons.logout),
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
                Get.offNamed('/home');
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
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/home', page: () => HomePage()),
      ],
    );
  }
}
