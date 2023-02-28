import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/event_bus_model/room_list_model.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/theme_dialog.dart';
import 'package:fb_live_flutter/live/widget/button/bottom_dialog_button.dart';
import 'package:fb_live_flutter/live/widget/dialog/common_bottom_menu.dart';
import 'package:fb_live_flutter/live/widget/dialog/common_bottom_tip.dart';
import 'package:fb_live_flutter/live/widget/dialog/complaint_receive_dialog.dart';
import 'package:fb_live_flutter/live/widget/dialog/complaint_submit_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'show_right_dialog.dart';

class DialogUtil {
  /*
  * 申诉已收到对话框
  * */
  static Future complaintReceive(BuildContext context, bool isAgain) {
    final double _h = FrameSize.winWidth() * 380 / 375;
    return showBottomSheetCommonDialog(
      context,
      height: _h,
      child: ComplaintReceiveDialog(_h, isAgain),
    );
  }

  /*
  * 提交申诉说明对话框
  * */
  static Future submitComplaint(
      BuildContext context, final RoomListModel? item) {
    final double _h = FrameSize.winWidth() * 234 / 375;
    return showBottomSheetCommonDialog(
      context,
      height: _h,
      child: ComplaintSubmitDialog(_h, item),
    );
  }

  /*
  * 发起手机屏幕共享提示
  * */
  static Future launchScreen(BuildContext context) {
    final double _h = FrameSize.winWidth() * 280 / 375;
    return showBottomSheetCommonDialog(
      context,
      height: _h,
      child: Container(
        height: _h,
        width: FrameSize.winWidth(),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 10.px),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '发起手机屏幕共享',
                style: TextStyle(
                  color: const Color(0xff1F2125),
                  fontSize: 18.px,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '共享后，所有频道内的成员都可看见你的手机屏幕。',
                style:
                    TextStyle(color: const Color(0xff8F959E), fontSize: 15.px),
              ),
              const BottomDialogButton(),
            ],
          ),
        ),
      ),
    );
  }

  /*
  * 无法恢复直播处理
  *
  * @param channelId String 房间的频道id
  * @param serverId String 房间的服务器id
  * @param roomId String 房间id
  * @param liveType int 直播类型
  * */
  static Future<bool> cantRestoreHandle(BuildContext context, String? channelId,
      String? serverId, String? roomId, int? liveType,
      {bool isShowDialog = true}) async {
    if (channelId != fbApi.getCurrentChannel()?.id ||
        serverId != fbApi.getCurrentChannel()!.guildId) {
      if (isShowDialog) {
        await DialogUtil.cantRestore(context, roomId, true);
      }
      return true;
    } else if (!kIsWeb) {
      if (liveType != 1 && liveType != 4 && liveType != 3) {
        if (isShowDialog) {
          await DialogUtil.cantRestore(context, roomId);
        }
        return true;
      }
    } else {
      if (liveType != 2) {
        if (isShowDialog) {
          await DialogUtil.cantRestore(context, roomId);
        }
        return true;
      }
    }
    return false;
  }

  /*
  * 无法恢复直播提示
  * */
  static Future cantRestore(BuildContext context, String? roomId,
      [bool isServer = false]) async {
    final String tipStr =
        "直播意外中断了，${isServer ? "恢复直播功能无法跨服务器或者频道使用" : '恢复直播功能无法跨越不同的系统使用'}，是否结束当前直播？";
    await ThemeDialog.themeDialogDoubleItem(
      context,
      title: '无法恢复直播提示',
      okText: "结束直播",
      text: tipStr,
      onPressed: () {
        if (roomId == null) {
          myFailToast("数据异常");
          return;
        }

        /// 【Web】跨端结束直播，点击直播列表中的直播间结束直播闪退
        /// 一定要先结束再刷新
        ///
        /// 应该调强制直播结束
        /// 【APP优先】【web】web跨端结束直播，APP端仍显示在直播，web端不能观看任何直播 @王增阳
        Api.mandatoryClose(roomId).then((value) {
          roomListEventBus.fire(LiveRoomListEvent());
        });
      },
    );
  }

  /*
  * 直播间将关闭
  * */
  static void liveWillClose(BuildContext? context, {VoidCallback? onPressed}) {
    ThemeDialog.themeDialogSingleItem(
      context,
      title: '直播间将关闭',
      okText: "知道了",
      cancelText: "查看详情",
      text: '当前直播涉及违规内容，直播间将被关闭，如有疑问请提交申诉说明',
      onPressed: () {
        if (onPressed != null) onPressed();
      },
      onCancel: () {
        if (onPressed != null) onPressed();
      },
    );
  }

  /*
  * 被踢出服务器
  * */
  static void kickOutServerClose(BuildContext? context, bool isAnchor,
      {VoidCallback? onPressed}) {
    ThemeDialog.themeDialogSingleItem(
      context,
      title: '直播间将关闭',
      okText: "知道了",
      cancelText: "查看详情",
      text: '因为你被踢出了服务器，直播间将${isAnchor ? "被关闭" : "无法观看"}，如有疑问请提交申诉说明',
      onPressed: () {
        if (onPressed != null) onPressed();
      },
      onCancel: () {
        if (onPressed != null) onPressed();
      },
    );
  }

  /*
  * 确定结束直播提示
  * */
  static Future confirmEndLiveTip(BuildContext? context,
      {VoidCallback? onPressed}) {
    return ThemeDialog.themeDialogDoubleItem(
      context,
      title: '提示',
      okText: "确定",
      text: '一大波观众正在赶来的路上，你确定要结束直播？',
      textAlign: TextAlign.center,
      onPressed: () {
        if (onPressed != null) onPressed();
      },
    );
  }

  /*
  * 送出礼物提示
  * */
  static void sendGift(BuildContext context,
      {String? text, VoidCallback? onPressed}) {
    ThemeDialog.themeDialogDoubleItem(
      context,
      title: '送出礼物',
      okText: "确定",
      text: text ?? '送出礼物，确定？',
      onPressed: () {
        if (onPressed != null) onPressed();
      },
    );
  }

  /*
  * 连接失败提示
  * */
  static void connectionFailureTip(
    BuildContext? context,
    bool isAnchor, {
    VoidCallback? onPressed,
    VoidCallback? onCancel,
  }) {
    ThemeDialog.themeDialogDoubleItem(
      context,
      title: '提示',
      okText: "重试",
      cancelText: "退出",
      text: isAnchor ? '当前网络质量不佳，请退出房间检查网络，正常后重新开启直播' : '直播间连接超时，可能主播不在，请稍后再试',
      onPressed: onPressed,
      onCancel: onCancel,
    );
  }

  /*
  * 连接失败提示
  * */
  static Future netConnectionFailureTip(
    BuildContext? context, {
    VoidCallback? onPressed,
    VoidCallback? onCancel,
  }) {
    return ThemeDialog.themeDialogDoubleItem(
      context,
      title: '提示',
      okText: "重试",
      cancelText: "退出",
      text: "连接不成功，\n检查网络之后再试？",
      textAlign: TextAlign.center,
      onPressed: onPressed,
      onCancel: onCancel,
    );
  }

  /*
  * 通用底部弹出提示
  * */
  static Future commonBottomTip(
    BuildContext context, {
    final VoidCallback? onNotAgain,
    final VoidCallback? onNow,
    final String? text,
  }) {
    final double _h = FrameSize.winWidth() * 280 / 375;
    return showBottomSheetCommonDialog(
      context,
      height: _h,
      child: CommonBottomTip(_h, onNotAgain, onNow, text),
    );
  }

  /*
  * 通用底部弹出菜单提示
  * */
  static Future commonBottomMenu(
    BuildContext context, {
    final VoidCallback? onConfirm,
    final VoidCallback? onCancel,
    final String? text,
  }) {
    final double _h = FrameSize.winWidth() * 190 / 375;
    return showBottomSheetCommonDialog(
      context,
      height: _h,
      child: CommonBottomMenu(_h, onConfirm, onCancel, text),
    );
  }
}
