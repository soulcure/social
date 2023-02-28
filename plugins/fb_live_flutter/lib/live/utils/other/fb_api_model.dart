import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/material.dart';

class FbApiModel {
  /*
  * 4.1、唤起用户个人信息弹窗【封装】
  * */
  static Future showUserInfoPopUp(
      BuildContext? context, String? userId, String? guildId) async {
    /// 是否开启横屏显示对话框【后期横屏组件兼容会需要，不能删除】
    // const bool isEnableHorizontal = false;

    // 宽度大于高度，判断为横屏【后期横屏组件兼容会需要，不能删除】
    // if (FrameSize.winWidth() > FrameSize.winHeight() && isEnableHorizontal) {
    // await showRightDialog(
    //   context!,
    //   widget: Container(
    //     color: Colors.white,
    //     width: FrameSize.winWidth() * (375 / 812),
    //     height: FrameSize.winHeight(),
    //     child: fbApi.userInfoComponent(context, userId, guildId: guildId),
    //   ),
    // );
    // } else {
    fbApi.showUserInfoPopUp(context!, userId!, guildId: guildId!);
    // }
  }

  /*
  * 直播违规触发通知
  * */
  static Future violationsAction(String? roomId) async {
    if (!strNoEmpty(roomId)) {
      return;
    }
    final String? _rId = fbApi.getSharePref("violationsAction");
    if (_rId == roomId) {
      return;
    }
    await fbApi.setSharePref("violationsAction", roomId!);
    await fbApi.pushNotification(
      title: "直播违规",
      content: "亲爱的主播，你的直播内容违规，直播已中断。",
      subtitle: "你的直播间违规",
    );
  }
}
