import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:replay_kit_launcher/replay_kit_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReplayKitLauncher _battery = ReplayKitLauncher();

  StreamSubscription? _batteryStateSubscription;

  String state = "";
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _battery.isScrren();
    });
    _batteryStateSubscription = _battery.getStream.listen((event) {
      if (state == event) {
        return;
      }
      state = event;
      print("状态变更拿到数据::$event");
    });
  }

  void launch() {
    // Please fill in the name of the Broadcast Extension in your project, which is the file name of the `.appex` product
    ReplayKitLauncher.launchReplayKitBroadcast('BroadcastDemoExtension');
  }

  void finish() {
    // Please fill in the CFNotification name in your project
    ReplayKitLauncher.finishReplayKitBroadcast(
        'ZGFinishBroadcastUploadExtensionProcessNotification');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ReplayKit Launcher example'),
          actions: [
            ElevatedButton(
              onPressed: () {
                _battery.isScrren();
              },
              child: Text('1'),
            )
          ],
        ),
        body: Center(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: ListView(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 50.0)),
                    Text('Only support iOS (12.0 or above)'),
                    Padding(padding: const EdgeInsets.only(top: 20.0)),
                    Text(
                      'You should create a new `Broadcast Upload Extension` Target in your iOS `Runner` project first, and use this plugin to launch the Extension by `RPSystemBroadcastPickerView`',
                      style: TextStyle(
                        fontSize: 11.0,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 20.0)),
                    Container(
                      padding: const EdgeInsets.all(0.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Color(0xff0e88eb),
                      ),
                      width: 240.0,
                      height: 50.0,
                      child: CupertinoButton(
                        child: Text(
                          'Launch ReplayKit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: launch,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 20.0)),
                    Container(
                      padding: const EdgeInsets.all(0.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Color(0xff0e88eb),
                      ),
                      width: 240.0,
                      height: 50.0,
                      child: CupertinoButton(
                        child: Text(
                          'Finish ReplayKit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: finish,
                      ),
                    )
                  ],
                ))),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;

    timer?.cancel();
    timer = null;
  }
}
