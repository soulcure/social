import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room_web_container.dart';
import 'package:fb_live_flutter/live/utils/live/goods_manage_light_util.dart';
import 'package:fb_live_flutter/live/utils/ui/window_util.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'live_room_obs.dart';

class RoomMiddlePage extends StatefulWidget {
  final LiveValueModel? liveValueModel;

  final bool? isOverlayViewPush; //是否是点击浮窗进入
  final bool? isWebFlip;

  // 是否来自直播列表页面
  final bool isFromList;

  // 是否来自预览
  final bool isFromPreview;

  // 当拉流第一帧后自动小窗化
  final bool autoFloatOnFirstFrame;

  const RoomMiddlePage({
    Key? key,
    this.isFromList = true,
    this.isFromPreview = false,
    this.isOverlayViewPush = false,
    this.isWebFlip,
    required this.liveValueModel,
    this.autoFloatOnFirstFrame = false,
  }) : super(key: key);

  @override
  _RoomMiddlePageState createState() => _RoomMiddlePageState();
}

class _RoomMiddlePageState extends State<RoomMiddlePage> {
  /// 模拟数据，判断是否为本频道成员,防止非正常手段或者Url方式进入【web和app通用】
  bool isChannelMembers = true;

  /*
  * 如果是主播的话就一定能访问了
  * */
  bool get isNotContent {
    return !isChannelMembers && !widget.liveValueModel!.isAnchor;
  }

  @override
  void initState() {
    super.initState();
    if (isNotContent) {
      Future.delayed(Duration.zero).then((value) {
        confirmSwDialog(
          context,
          text: '抱歉，你不是本频道成员',
        ).then((value) {
          fbApi.globalNavigatorKey.currentState!.pop();
        });
      });
      return;
    }

    /// 不是悬浮窗进入则清空呼吸灯内存数据
    if (widget.isOverlayViewPush == null || !widget.isOverlayViewPush!) {
      GoodsManageCartUtil.goodsCartLightModel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isNotContent) {
      return const Scaffold();
    } else if (kIsWeb) {
      return LiveRoomWebContainer(
        key: widget.key,
        isWebFlip: widget.isWebFlip,
        roomId: widget.liveValueModel!.roomInfoObject!.roomId,
        isFromList: widget.isFromList,
        liveValueModel: widget.liveValueModel,
      );
    } else if (widget.liveValueModel!.getIsObs &&
        widget.liveValueModel!.isAnchor) {
      return LiveRoomObs(
        key: widget.key,
        isOverlayViewPush: widget.isOverlayViewPush,
        isFromList: widget.isFromList,
        liveValueModel: widget.liveValueModel,
        autoFloatOnFirstFrame: widget.autoFloatOnFirstFrame,
      );
    } else {
      return LiveRoom(
        key: widget.key,
        isOverlayViewPush: widget.isOverlayViewPush,
        isFromList: widget.isFromList,
        isFromPreview: widget.isFromPreview,
        liveValueModel: widget.liveValueModel,
        autoFloatOnFirstFrame: widget.autoFloatOnFirstFrame,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    // 状态栏字体颜色设置为黑色
    WindowUtil.setStatusTextColorBlack();
  }
}
