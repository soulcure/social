/*
创建直播房间
 */

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/create_room_bloc.dart';
import 'package:fb_live_flutter/live/pages/create_room/v2/room_info_card.dart';
import 'package:fb_live_flutter/live/pages/playback/widget/live_logo_background.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/window_util.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/switch.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/create_room_bloc.dart';
import '../../event_bus_model/refresh_room_list_model.dart';
import '../../utils/manager/event_bus_manager.dart';
import '../../utils/ui/frame_size.dart';
import '../../utils/ui/ui.dart';
import '../../widget_common/appbar/navigation_bar.dart';
import '../../widget_common/sw_list_tile.dart';

class CreateRoom extends StatefulWidget {
  final String nickName;

  /// 开播频道，添加此参数的原因：
  /// 之前可以直接获取当前选中频道即可，因虚拟社区开播功能加入，调用开播接口时当前选中频道
  /// 并不一定为开播频道，需要从上层传过来
  final FBChatChannel? liveChannel;

  const CreateRoom({Key? key, required this.nickName, this.liveChannel})
      : super(key: key);

  @override
  CreateRoomV2State createState() => CreateRoomV2State();
}

/// 创建直播页面-直播带货-版本2
class CreateRoomV2State extends State<CreateRoom> {
  final CreateRoomBloc _createRoomBloc = CreateRoomBloc();

  final Color lineColor = const Color(0xff8F959E).withOpacity(0.2);

  @override
  void initState() {
    super.initState();
    _createRoomBloc.initBloc(creteRoom: this, liveChannel: widget.liveChannel);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateRoomBloc, int>(
      builder: (context, value) {
        return MyScaffold(
          overlayStyle: SystemUiOverlayStyle.light,
          resizeToAvoidBottomInset: false,
          removeTop: true,
          body: Stack(
            children: [
              LiveLogoBackground(
                _createRoomBloc.imageUrl,
                color: Colors.black.withOpacity(0.5),
              ),

              /// 【APP】iPhoneX 创建直播间页面最下面有一块黑色区域
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.only(top: FrameSize.statusBarHeight()),
                      height: FrameSize.topBarHeight(),
                      child: const NavigationBar(
                        title: '创建直播间',
                        backgroundColor: Colors.transparent,
                        mainColor: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: kIsWeb
                          ? Center(child: childWidget(context))
                          : childWidget(context),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
      bloc: _createRoomBloc,
    );
  }

  Widget switchBuild(List e) {
    return SwListTileOld(
      inBorder: Border(
        bottom: BorderSide(
          color:
              e[2] == CreateRoomItemType.goods && !_createRoomBloc.isGoodsValue
                  ? Colors.transparent
                  : lineColor,
          width: 0.5,
        ),
      ),
      inPadding: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(0),
      title: Padding(
        padding: EdgeInsets.only(bottom: 4.px),
        child: Text(
          e[0],
          style: TextStyle(color: Colors.white, fontSize: FrameSize.px(15)),
        ),
      ),
      subtitle: Text(
        e[1],
        style: TextStyle(
            color: Colors.white.withOpacity(0.35), fontSize: FrameSize.px(13)),
      ),
      trailing: StatefulBuilder(
        builder: (context, refreshState) {
          final bool isOut = e[2] == CreateRoomItemType.obs;
          final bool isGoods = e[2] == CreateRoomItemType.goods;

          /// 【APP】创建直播间页开关按钮样式不对，间距也不对
          /// 2021 11.02
          return Transform.scale(
            scale: 0.8,
            child: MyCupertinoSwitch(
              value: isOut
                  ? _createRoomBloc.isExternal
                  : isGoods
                      ? _createRoomBloc.isGoodsValue
                      : _createRoomBloc.isPrivacy,
              activeColor: MyTheme.themeSwitchColor,
              onChanged: (value) {
                _createRoomBloc.switchChange(
                    isOut, isGoods, value, refreshState);
              },
            ),
          );
        },
      ),
    );
  }

  Widget childWidget(BuildContext context) {
    return Container(
      width: kIsWeb ? 375 : FrameSize.screenW(),
      padding: EdgeInsets.only(left: FrameSize.px(16), right: FrameSize.px(16)),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: FrameSize.px(36)),
                  RoomInfoCard(
                    imageCallBlock: (imageUrl) {
                      _createRoomBloc.setImageUrl(imageUrl!);
                    },
                    createRoomBloc: _createRoomBloc,
                  ),
                  Space(height: 24.px),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff000000).withOpacity(0.25),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Column(
                      children: _createRoomBloc.items.map(switchBuild).toList()
                        ..add(
                          _createRoomBloc.isGoodsValue
                              ? ClickEvent(
                                  onTap: () async {
                                    await _createRoomBloc.pushAidSet();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    margin: EdgeInsets.only(bottom: 20.px),
                                    child: Row(
                                      children: [
                                        Text(
                                          '直播小助手设置',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.px,
                                          ),
                                        ),
                                        const Space(),
                                        Expanded(
                                          child: Text(
                                            _createRoomBloc.showAidStr,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.px),
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SwImage(
                                          'assets/live/main/v2_create_arrow_right.png',
                                          width: 16.px,
                                          height: 16.px,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(),
                        ),
                    ),
                  ),
                  Space(height: FrameSize.px(10)),
                ],
              ),
            ),
          ),
          SizedBox(height: FrameSize.px(26)),
          Center(
            child: SizedBox(
              width: FrameSize.screenW() - (67.5 * 2),
              height: FrameSize.px(40),
              child: CupertinoButton(
                padding: const EdgeInsets.all(0),
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.all(Radius.circular(20.px)),
                onPressed: () {
                  _createRoomBloc.interLive(context);
                },
                child: Text(
                  "开始直播",
                  style: TextStyle(fontSize: 16.px),
                ),
              ),
            ),
          ),
          if (kIsWeb)
            SizedBox(height: FrameSize.px(26))
          else
            SizedBox(height: FrameSize.px(0)),
          if (kIsWeb) webBackView() else Container(),
          SizedBox(height: FrameSize.px(19.px)),
          Container(
            alignment: Alignment.center,
            child: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                      text: "点击开始直播即代表同意",
                      style: TextStyle(
                          color: const Color(0xFFF3F8FF).withOpacity(0.35),
                          fontSize: FrameSize.px(12),
                          decoration: TextDecoration.none)),
                  TextSpan(
                    text: "《Fanbook直播协议》",
                    style: TextStyle(
                        color: const Color(0xffffffff),
                        fontSize: FrameSize.px(12),
                        decoration: TextDecoration.none),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final liveUrl =
                            'https://${configProvider.protocolHost}/live/live.html';
                        fbApi.pushHTML(context, liveUrl, title: '用户直播协议');
                      },
                  ),
                ],
              ),
            ),
          ),
          Space(height: 19.px),
        ],
      ),
    );
  }

  Widget webBackView() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        EventBusManager.eventBus.fire(RefreshRoomListModel(true));
      },
      child: Container(
        alignment: Alignment.center,
        width: 375,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(FrameSize.px(6))),
        ),
        child: const Text(
          "返回",
          style: TextStyle(
              color: Color(0xFF6379F1),
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _createRoomBloc.close();
    // 设置状态栏颜色为黑色
    WindowUtil.setStatusTextColorBlack();
  }
}
