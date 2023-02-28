import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fb_carrier_info_plugin/fb_carrier_info_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _netWorkType = 'Unknown';
  String _operatorType = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String netWorkType;
    String operatorType;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      netWorkType = await FbCarrierInfoPlugin.netWorkType;

      operatorType = await FbCarrierInfoPlugin.operatorType;
    } on PlatformException {
      netWorkType = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _netWorkType = netWorkType;
      _operatorType = operatorType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_netWorkType\n  +  $_operatorType'),
        ),
      ),
    );
  }
}
