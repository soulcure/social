import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';

/// - 描述：禁言监听器控件
///
/// - author: seven
/// - data: 2021/12/17 10:41 上午

/// - isMuted: 是否被禁言
/// - muteTime: 禁言时长，单位秒
typedef MuteBuilder = Widget Function(bool isMuted, int muteTime);

class MuteListenerWidget extends StatelessWidget {
  final MuteBuilder builder;

  const MuteListenerWidget({@required this.builder, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MuteListenerController>(
        init: MuteListenerController.to,
        builder: (controller) {
          return builder(controller.muteTime > 0, controller.muteTime);
        });
  }
}
