import 'dart:io';

// 解决连接自签名服务失败的情形。
// 注：web端无效
// https://github.com/dart-lang/http/issues/458
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}