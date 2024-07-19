import 'dart:async';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'dart:typed_data' show Uint8List;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'insta_assets_picker插件示例'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<Uint8List?> readAlbumPhoto(BuildContext context) async {
  final completer = Completer<Uint8List?>();

  final theme = InstaAssetPicker.themeData(Theme.of(context).primaryColor);
  await InstaAssetPicker.pickAssets(
    context,
    title: '选择图像',
    maxAssets: 1,
    onCompleted: (Stream<InstaAssetsExportDetails> stream) {
      stream.listen((data) async {
        if (data.progress == 1.0) {
          print('stream data progress:${data.progress} aspectRatio:${data.aspectRatio}');
          final imageBytes = await data.croppedFiles.first.readAsBytes();
          completer.complete(imageBytes); // 完成 Completer
        }
      });
    },
    onPermissionDenied: (context, delegateDescription) {
      print('访问相册被拒绝');
      completer.complete(null); // 处理权限被拒绝的情况
    },
    cropDelegate: InstaAssetCropDelegate(preferredSize: 1080, cropRatios: [3/4]),
    pickerTheme: theme.copyWith(
      // ... 省略其他配置
    ),
    closeOnComplete: true,
    textDelegate: AssetPickerTextDelegate(),
  );

  return completer.future; // 返回 Completer 的 future
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? _imageBytes;

  // 头像
  Widget avatar() {
    return Container(
        width: 150,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(width: 1.0, color: Colors.lightBlueAccent),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _imageBytes != null
              ? Center(
                  child: Image.memory(
                    _imageBytes!,
                    width: 150, // 设置图像的宽度
                    height: 200, // 设置图像的高度
                    fit: BoxFit.cover, // 设置适应模式
                  ),
                )
              : Icon(
                  Icons.photo_album_outlined,
                  size: 150,
                ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Container(
          alignment: Alignment.center,
          color: Colors.lightGreen,
          child: Column(
            children: [
              ElevatedButton(
                child: Text('单个'),
                onPressed: () async {
                  // 直接使用wechat_assets_picker
                  // try{
                  //   final List<AssetEntity>? result =
                  //   await AssetPicker.pickAssets(context);
                  //   print('选择结束 $result');
                  // }catch(e){
                  //   print('AssetPicker.pickAssets异常 $e');
                  // }

                  _imageBytes = await readAlbumPhoto(context);
                  setState(() { });
                },
              ),
              avatar(),
            ],
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
