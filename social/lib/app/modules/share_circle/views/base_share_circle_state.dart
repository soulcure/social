import 'package:flutter/material.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle.dart';

abstract class BaseShareCircleState extends State<ShareCircle> {
  final ShareBean shareBean;

  BaseShareCircleState(this.shareBean);
}
