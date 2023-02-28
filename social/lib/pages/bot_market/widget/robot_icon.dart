import 'package:flutter/material.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/common/extension/string_extension.dart';

class RobotAvatar extends StatelessWidget {
  final String url;
  final double radius;

  const RobotAvatar({Key key, this.url, this.radius = 12}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!url.hasValue) {
      return CircleAvatar(
        radius: radius,
        child: Image.asset("assets/images/robot_icon.png"),
      );
    }
    return FlutterAvatar(url: url, radius: radius);
  }
}
