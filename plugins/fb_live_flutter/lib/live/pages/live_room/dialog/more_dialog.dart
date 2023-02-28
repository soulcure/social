import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/other/ios_screen_plugin.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:media_projection_creator/media_projection_creator.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../../utils/config/sp_key.dart';
import '../../../utils/func/router.dart';
import '../../../utils/live/zego_manager.dart';
import '../../../utils/theme/my_toast.dart';
import '../../../utils/ui/frame_size.dart';
import '../../../utils/ui/ui.dart';
import '../../../widget_common/dialog/sw_dialog.dart';

Future moreDialog(BuildContext context, LiveMoreInterface? more, bool isObs,
    final LiveValueModel liveValueModel) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return MoreDialog(more, isObs, liveValueModel);
    },
  );
}

/*
* 【更多对话框】item类型
* */
enum MoreDialogItemType {
// 翻转
  flip,
// 镜像
  mirror,
// 停止共享
  screenShareStop,
// 屏幕共享
  screenShare,
// 分享
  share,
}

/*
* 【更多对话框】item模型
* */
class MoreDialogItemModel {
  final String image;
  final String text;
  final MoreDialogItemType value;

  MoreDialogItemModel(this.image, this.text, this.value);
}

class MoreDialog extends StatefulWidget {
  final LiveMoreInterface? more;
  final bool isObs;
  final LiveValueModel? liveValueModel;

  const MoreDialog(this.more, this.isObs, this.liveValueModel);

  @override
  _MoreDialogState createState() => _MoreDialogState();
}

class _MoreDialogState extends State<MoreDialog> {
  /// 【2021 12.06】修复obs主播端打开更多按钮失败
  bool get isScreenSharing {
    if (widget.isObs) {
      return false;
    }
    return widget.liveValueModel!.isScreenSharing;
  }

  List<MoreDialogItemModel> get data {
    /// 屏幕共享item
    MoreDialogItemModel screenItem;
    if (isScreenSharing) {
      /// 已经是屏幕共享了，显示停止屏幕共享
      screenItem = MoreDialogItemModel("assets/live/main/ic_screen_stop.png",
          "停止共享", MoreDialogItemType.screenShareStop);
    } else {
      /// 没有开始屏幕共享，显示屏幕共享
      screenItem = MoreDialogItemModel('assets/live/main/ic_screen_share.png',
          '屏幕共享', MoreDialogItemType.screenShare);
    }

    return [
      MoreDialogItemModel('assets/live/main/ic_more_preview_flip.png', '翻转',
          MoreDialogItemType.flip),
      MoreDialogItemModel('assets/live/main/ic_more_mirror.png', '镜像',
          MoreDialogItemType.mirror),
      screenItem,
      MoreDialogItemModel(
          'assets/live/main/ic_more_share.png', '分享', MoreDialogItemType.share),
    ];
  }

  Widget itemBuild(MoreDialogItemModel e) {
    final bool isShare = e.value == MoreDialogItemType.share;

    final bool isScreenStr = e.value == MoreDialogItemType.flip ||
        e.value == MoreDialogItemType.mirror;
    final bool isScreenOpacity = isScreenStr && isScreenSharing;

    final bool isOpacity = (widget.isObs && !isShare) || isScreenOpacity;
    final Color color = Colors.white.withOpacity(isOpacity ? 0.5 : 1);
    return InkWell(
      onTap: () => action(e.value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30.px),
        width: (FrameSize.winWidth() - 20.px) / 4,
        child: Column(
          children: [
            Image.asset(
              e.image,
              color: isShare ? null : color,
              width: 21.99.px,
            ),
            const Space(),
            Text(
              e.text,
              style: TextStyle(color: color, fontSize: FrameSize.px(14)),
            ),
          ],
        ),
      ),
    );
  }

  /*
  * 屏幕共享
  * */
  Future screenShare() async {
    final String? cantUseHeadphonesTip =
        fbApi.getSharePref(SpKey.cantUseHeadphonesTip);
    if (cantUseHeadphonesTip == null || cantUseHeadphonesTip == "0") {
      await DialogUtil.commonBottomTip(context, onNotAgain: () {
        fbApi.setSharePref(SpKey.cantUseHeadphonesTip, "1");
      });
    }
    RouteUtil.pop();
    final String? screenShareTip = fbApi.getSharePref(SpKey.screenShareTip);
    if (screenShareTip == null || screenShareTip == "0") {
      await confirmSwDialog(
        context,
        text: '共享后，所有频道内的成员都可看见你的手机屏幕',
        title: '发起手机屏幕共享',
        okText: "我知道了",
        cancelText: '不再提示',
        onCancel: () {
          fbApi.setSharePref(SpKey.screenShareTip, "1");
        },
      );
    }
    await Future.delayed(kThemeAnimationDuration).then((value) async {
      await handleScreenShare();
    });
  }

  /*
  * 屏幕共享处理
  * */
  Future handleScreenShare() async {
    if (widget.liveValueModel!.zegoTokenModel == null) {
      myFailToast('出现错误');
      return;
    }

    widget.liveValueModel!.isScreenSharing = true;

    if (Platform.isIOS) {
      await ZegoExpressEngine.instance.enableCamera(false);
      widget.more!.showScreenSharingBlocModel?.add(false);
      await ZegoExpressEngine.instance.setStreamExtraInfo(sendSteamInfo(
          screenShare: true,
          mirror: false,
          liveValueModel: widget.liveValueModel!));
      await ZegoManager.changeScreenShareIos(
          widget.liveValueModel!.zegoTokenModel);
    } else {
      await ZegoManager.changeScreenShare(
          widget.liveValueModel!.zegoTokenModel!,
          start: startScreen, cancel: () {
        widget.more!.isScreenProcess = true;
        widget.liveValueModel!.isScreenSharing = false;

        /// 选择不开始共享 -主播刷新直播间视图【2022 03-05】
        ///
        /// 因为Android当打开原生【是否开始屏幕共享】页面时，小窗就会执行抢占预览了，
        /// 当取消时【选择不开始共享】，直播需要刷新视图，抢占会预览。
        widget.more!.refreshLiveView();
      });
    }
  }

  // ui更新为共享状态
  void startScreen() {
    if (Platform.isAndroid) {
      ZegoExpressEngine.instance.setStreamExtraInfo(sendSteamInfo(
          screenShare: true,
          mirror: false,
          liveValueModel: widget.liveValueModel!));
    }
    ZegoExpressEngine.instance.enableCamera(false);
    widget.more!.showImageFilterBlocModel?.add(false);
    widget.more!.showScreenSharingBlocModel?.add(false);
  }

  void action(MoreDialogItemType value) {
    // obs直播主播端底部按钮根据设计图来
    if (widget.isObs && value != MoreDialogItemType.share) {
      /// 【APP】屏幕共享不可用按钮未置灰
      /// 【2021 12.22】 不可用提示去掉
      // myToast("OBS推流不支持使用该功能");
      return;
    }
    switch (value) {
      case MoreDialogItemType.screenShare:
        screenShare();
        break;
      case MoreDialogItemType.screenShareStop:
        RouteUtil.pop();
        stopShare();
        break;
      case MoreDialogItemType.flip:
        if (widget.liveValueModel!.isScreenSharing) {
          /// 【2021 12.22】 不可用提示去掉
          // myFailToast('屏幕共享不支持翻转');
          return;
        }
        RouteUtil.pop(0);
        break;
      case MoreDialogItemType.mirror:
        if (widget.liveValueModel!.isScreenSharing) {
          /// 【2021 12.22】 不可用提示去掉
          // myFailToast('屏幕共享不支持镜像');
          return;
        }
        RouteUtil.pop(1);
        break;
      case MoreDialogItemType.share:
        RouteUtil.pop(2);
        break;
      default:
        myToast("敬请期待");
        break;
    }
  }

  Future stopShare() async {
    widget.liveValueModel!.isScreenSharing = false;
    await stopShareAction();
  }

  Future stopShareAction() async {
    // 关闭捕捉屏幕能力
    if (Platform.isIOS) {
      await ReplayKitLauncher.finishReplayKitBroadcast(
          configProvider.broadcastNotificationName);
      await IosScreenPlugin.stopGetData();
    } else {
      await MediaProjectionCreator.destroyMediaProjection();
    }
    await ZegoManager.changeLive(widget.liveValueModel!);

    await Future.delayed(const Duration(milliseconds: 1000)).then((value) {
      widget.more!.showImageFilterBlocModel?.add(true);
      widget.more!.showScreenSharingBlocModel?.add(true);
    });

    final ZegoVideoMirrorMode mirrorMode = widget.liveValueModel!.isMirror
        ? ZegoVideoMirrorMode.BothMirror
        : ZegoVideoMirrorMode.NoMirror;
    await ZegoExpressEngine.instance.setVideoMirrorMode(mirrorMode);
    if (widget.more!.isFromOverlayFirstScreen ?? false) {
      widget.more!.isFromOverlayFirstScreen = false;
      widget.more!.onRefresh();
    }

    /// 【2021 12.23】
    /// 停止共享后开启刷新直播画面，防止主播摄像头画面卡住
    /// 【APP】停止屏幕共享后，普通直播主播卡在最后一帧
    unawaited(widget.more!.refreshLiveView());
  }

  @override
  Widget build(BuildContext context) {
    final double vertical = 62.px;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: vertical, horizontal: 10.px),
            child: Material(
              borderRadius: BorderRadius.all(Radius.circular(8.px)),
              color: const Color(0xff111111),
              child: Row(children: data.map(itemBuild).toList()),
            ),
          )
        ],
      ),
    );
  }
}
