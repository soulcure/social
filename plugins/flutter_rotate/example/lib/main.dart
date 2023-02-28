import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rotate/flutter_rotate.dart';

void main() {
  const SystemUiOverlayStyle systemUiOverlayStyle =
      SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  WidgetsFlutterBinding.ensureInitialized();

  //强制竖屏
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isScreenRotation = false;

  @override
  void initState() {
    super.initState();
    FlutterRotate.reg();
  }

  @override
  void dispose() {
    FlutterRotate.unreg();
    super.dispose();
  }

  /*
  * 设置系统竖屏
  * */
  Future setSystemPortraitVertical() async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    ///  flutter 旧版
    // ignore: deprecated_member_use
    await SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
  }

  /*
  * 设置系统横屏
  * */
  Future setSystemPortraitHorizontal(DeviceOrientation orientation) async {
    await SystemChrome.setPreferredOrientations([orientation, orientation]);

    // ignore: deprecated_member_use
    await SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
  }

  Future change() async {
    isScreenRotation = !isScreenRotation;
    if (isScreenRotation) {      FlutterRotate.changeHorizontal();

    setSystemPortraitHorizontal(Platform.isIOS
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft);
    } else {
      FlutterRotate.changeVertical();
      setSystemPortraitVertical();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            TextButton(
              onPressed: () {
                change();
              },
              child: const Text('旋转'),
            )
          ],
        ),
        body: const Center(
          child: Text('Running on:'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
