
import 'package:flutter/material.dart';

class WebVideoPage extends StatefulWidget {
  @override
  _WebVideoPageState createState() => _WebVideoPageState();
}

class _WebVideoPageState extends State<WebVideoPage> {



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
//        _enterFullScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: build(context),
        ),
      ),
    );
  }


}
