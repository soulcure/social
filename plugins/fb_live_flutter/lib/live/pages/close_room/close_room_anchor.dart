import 'dart:async';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/close_room/close_room_logic.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:fb_live_flutter/live/widget_common/view/blurred_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../event_bus_model/refresh_room_list_model.dart';
import '../../model/colse_room_model.dart';
import '../../model/room_infon_model.dart';
import '../../utils/manager/event_bus_manager.dart';

class CloseRoom extends StatefulWidget {
  final CloseRoomModel? closeRoomModel;
  final RoomInfon? roomInfoObject;
  final String? roomId;
  final String? shareType;
  final String? tipString;
  final LiveValueModel? liveValueModel;

  const CloseRoom({
    Key? key,
    this.closeRoomModel,
    this.roomInfoObject,
    this.roomId,
    this.tipString,
    this.shareType,
    required this.liveValueModel,
  }) : super(key: key);

  @override
  _CloseRoomState createState() => _CloseRoomState();
}

class _CloseRoomState extends State<CloseRoom> with CloseRoomLogic {
  RoomInfon? roomInfoObject;

  final ValueNotifier<String> _anchorNameNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    closeRoomModel = widget.closeRoomModel;
    roomInfoObject = widget.roomInfoObject;

    /// 结束页检测小窗【关闭小窗方法，Android和iOS通用】
    unawaited(FloatUtil.dismissFloat(200));

    getRoomInfo();
    _getAnchorName();
    getData();

    /// 【2021 11。30】主播直播结束清除附加消息内存储的屏幕共享状态
    /// 屏幕共享状态内存的要清除，否则下次开播还是发送了附加消息为屏幕共享打开了
    widget.liveValueModel!.steamInfoStore.screenShare = false;
  }

  Future _getAnchorName() async {
    _anchorNameNotifier.value = await fbApi.getShowName(
      widget.roomInfoObject!.anchorId!,
      guildId: widget.roomInfoObject!.serverId,
    );
  }

  // 主播退出直播间
  Future getData() async {
    if (!strNoEmpty(widget.roomId)) {
      return;
    }
    final Map status = await Api.liveStatistics(widget.roomId!);
    if (status["code"] == 200) {
      closeRoomModel = CloseRoomModel.fromJson(status["data"]);
      if (mounted) setState(() {});
    } else {
      myFailToast('出现错误');
    }
  }

  Future getRoomInfo() async {
    if (roomInfoObject == null) {
      final Map resultData = await Api.getRoomInfo(widget.roomId!);
      if (resultData["code"] == 200) {
        roomInfoObject = RoomInfon.fromJson(resultData["data"]);
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 状态栏刷新调用
    statusBarRefresh();
    return MyScaffold(
      body: BlurredPicture(
        backgroundImage: roomInfoObject?.roomLogo ?? '',
        //直播结束页面
        child: Padding(
          padding: EdgeInsets.only(
              left: FrameSize.px(17),
              right: FrameSize.px(17),
              top: FrameSize.padTopH()),
          child: Column(
            children: [
              SizedBox(height: FrameSize.px(16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: FrameSize.px(23)),
                  Text(
                    '直播结束',
                    style: TextStyle(
                      fontSize: FrameSize.px(17),
                      color: Colors.white,
                    ),
                  ),
                  ClickEvent(
                    onTap: () async {
                      // 直播关闭提示页并不一定返回到home主页，只需要返回上一个页面即可
                      // fbApi.backToLiveRoomList(context: context);
                      Get.back();

                      EventBusManager.eventBus.fire(RefreshRoomListModel(true));
                      SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle.dark);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(FrameSize.px(5)),
                      child: Image.asset(
                        'assets/live/LiveRoom/close.png',
                        width: FrameSize.px(18),
                        height: FrameSize.px(18),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: FrameSize.px(3)),
              Text(
                () {
                  if (strNoEmpty(widget.tipString)) {
                    return widget.tipString;
                  } else if (isLessOneMin) {
                    return '直播时间较短，将不会生成回放';
                  } else if (roomInfoObject?.status == 4) {
                    return '直播可能存在不良信息，可前往回放观看内容';
                  } else {
                    return '回放将在几分钟之后生成';
                  }
                }()!,
                style: TextStyle(
                  fontSize: FrameSize.px(13),
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              SizedBox(height: FrameSize.px(36)),
              Text(
                '你的直播很精彩,\n期待下次开播!',
                style: TextStyle(
                  fontSize: FrameSize.px(24),
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: FrameSize.px(42)),
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                margin: EdgeInsets.symmetric(horizontal: FrameSize.px(9)),
                width: kIsWeb ? FrameSize.px(375) : FrameSize.screenW(),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.1)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16, top: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fbApi.realtimeAvatar(
                            roomInfoObject?.anchorId ?? "",
                            size: 62,
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(
                                  left: FrameSize.px(7), top: FrameSize.px(6)),
                              child: ValueListenableBuilder<String>(
                                valueListenable: _anchorNameNotifier,
                                builder: (context, anchorName, child) {
                                  return Text(
                                    anchorName,
                                    style: TextStyle(
                                      fontSize: FrameSize.px(17),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: FrameSize.px(25)),
                    Wrap(
                      runSpacing: FrameSize.px(20),
                      children: [
                        [timeStr, '直播时长'],
                        [
                          UtilsClass.calcNum(widget.closeRoomModel?.audience ??
                              closeRoomModel?.audience ??
                              0),
                          '观看次数'
                        ],
                        [
                          UtilsClass.calcNum(
                              widget.closeRoomModel?.thumbCount ??
                                  closeRoomModel?.thumbCount ??
                                  0),
                          '点赞数'
                        ],
                        [
                          UtilsClass.calcNum(int.parse(
                              widget.closeRoomModel?.coin ??
                                  closeRoomModel?.coin ??
                                  "0")),
                          '乐豆数'
                        ],
                      ].map((item) {
                        return Container(
                          padding: EdgeInsets.only(bottom: FrameSize.px(9)),
                          width: kIsWeb
                              ? FrameSize.px(375) / 3
                              : (FrameSize.screenW() - FrameSize.px(72)) / 3,
                          child: Column(
                            children: [
                              Text(
                                item[0],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: FrameSize.px(17),
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(height: FrameSize.px(3)),
                              Text(
                                item[1],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: FrameSize.px(13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: FrameSize.px(40)),
              if (!isLessOneMin && roomInfoObject?.status != 4)
                ClickEvent(
                  onTap: () async {
                    bool canWatchOutside;
                    if (widget.shareType == "1") {
                      canWatchOutside = true;
                    } else {
                      canWatchOutside = false;
                    }
                    final FBShareContent fbShareContent = FBShareContent(
                      type: ShareType.playback,
                      roomId: roomInfoObject!.roomId,
                      canWatchOutside: canWatchOutside,
                      guildId: roomInfoObject!.serverId,
                      channelId: roomInfoObject!.channelId,
                      coverUrl: roomInfoObject!.avatarUrl!,
                      anchorName: roomInfoObject!.nickName!,
                    );
                    await fbApi.showShareLinkPopUp(context, fbShareContent);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '分享回放',
                        style: TextStyle(
                          fontSize: FrameSize.px(13),
                          color: const Color(0xff6179f2),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            left: FrameSize.px(4), top: FrameSize.px(1.5)),
                        child: Image.asset(
                          "assets/live/LiveRoom/arrow_right.png",
                          color: const Color(0xff6179f2),
                          width: FrameSize.px(12.5),
                          height: FrameSize.px(12.5),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(),
            ],
          ),
        ),
      ),
    );
  }
}
