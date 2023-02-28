import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/colse_room_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:fb_live_flutter/live/widget_common/view/blurred_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../event_bus_model/refresh_room_list_model.dart';
import '../../model/close_audience_room_model.dart';
import '../../utils/func/utils_class.dart';
import '../../utils/manager/event_bus_manager.dart';

class CloseAudienceRoom extends StatefulWidget {
  final String? roomId;
  final CloseAudienceRoomModel? closeAudienceRoomModel;
  final String? tipString;

  const CloseAudienceRoom(
      {Key? key, this.roomId, this.closeAudienceRoomModel, this.tipString})
      : super(key: key);

  @override
  _CloseAudienceRoomState createState() => _CloseAudienceRoomState();
}

class _CloseAudienceRoomState extends State<CloseAudienceRoom> {
  CloseRoomModel? closeAudienceRoom;
  final ValueNotifier<String> _anchorNameNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    //强制竖屏
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }

    /// 结束页检测小窗
    unawaited(FloatUtil.dismissFloat(200));
    _getAnchorName();
    getData();
  }

  Future _getAnchorName() async {
    _anchorNameNotifier.value = await fbApi.getShowName(
      widget.closeAudienceRoomModel!.userId!,
      guildId: widget.closeAudienceRoomModel!.serverId!,
    );
  }

  // 观众退出直播间
  Future getData() async {
    final Map status = await Api.liveStatistics(widget.roomId!);
    if (status["code"] == 200) {
      closeAudienceRoom = CloseRoomModel.fromJson(status["data"]);
      setState(() {});
    } else {
      showToast('出现错误');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E122A),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage("assets/live/LiveRoom/live_bgImage.png"),
          ),
        ),
        width: FrameSize.screenW(),
        height: FrameSize.screenH(),
        child: BlurredPicture(
          backgroundImage: widget.closeAudienceRoomModel?.roomLogo,
          //直播结束页面
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  left: FrameSize.px(30), right: FrameSize.px(30)),
              child: Column(
                children: [
                  _closeBtn(context),
                  _anchorImage(),
                  SizedBox(
                    height: FrameSize.px(12),
                  ),
                  ValueListenableBuilder<String>(
                      valueListenable: _anchorNameNotifier,
                      builder: (context, anchorName, child) {
                        return Text(
                          anchorName,
                          style: TextStyle(
                              color: Colors.white, fontSize: FrameSize.px(14)),
                        );
                      }),
                  const Spacer(),
                  Text(
                    '直播已结束',
                    style: TextStyle(
                        color: Colors.white, fontSize: FrameSize.px(24)),
                  ),
                  SizedBox(height: FrameSize.px(12)),
                  Text(
                    widget.tipString ?? '回放正在生成中，请稍后查看',
                    style: TextStyle(
                        color: const Color(0xFFAEAEAE),
                        fontSize: FrameSize.px(14)),
                  ),
                  SizedBox(height: FrameSize.px(12)),
                  Text(
                    "本场累计 ${UtilsClass.calcNum(closeAudienceRoom?.audience)} 人次观看",
                    style: TextStyle(
                        color: const Color(0xFFAEAEAE),
                        fontSize: FrameSize.px(14)),
                  ),
                  const Spacer(flex: 2),
                  GestureDetector(
                    onTap: () {
                      // 直播关闭提示页并不一定返回到home主页，只需要返回上一个页面即可
                      // fbApi.backToLiveRoomList(context: context);
                      Get.back();
                      EventBusManager.eventBus.fire(RefreshRoomListModel(true));
                      SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle.dark);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: FrameSize.px(110),
                      height: FrameSize.px(40),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white, width: FrameSize.px(1)),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Text("返回",
                          style: TextStyle(
                              color: Colors.white, fontSize: FrameSize.px(16))),
                    ),
                  ),
                  const Spacer(),
                  Space(height: 10.px),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _anchorImage() {
    return Container(
      height: FrameSize.px(48),
      width: FrameSize.px(48),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FrameSize.px(24)),
          color: Colors.blue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FrameSize.px(24)),
        child: Image(
          image: (widget.closeAudienceRoomModel?.avatarUrl == null
                  ? fbApi.getFanbookIcon()
                  : NetworkImage(widget.closeAudienceRoomModel!.avatarUrl!))
              as ImageProvider<Object>,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _closeBtn(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: FrameSize.screenW() - FrameSize.px(90), top: FrameSize.px(30)),
      child: GestureDetector(
        onTap: () {
          /// 【2022 0124】直接把调用 这个backToLiveRoomList的地衣改成Get.back()
          // fbApi.backToLiveRoomList(context: context);
          Get.back();

          EventBusManager.eventBus.fire(RefreshRoomListModel(true));
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        },
        child: SizedBox(
          width: FrameSize.px(60),
          height: FrameSize.px(30),
          child: Image.asset("assets/live/LiveRoom/close_btn.png",
              width: FrameSize.px(20), height: FrameSize.px(20)),
        ),
      ),
    );
  }
}
