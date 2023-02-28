/*
直播界面主播底部按钮
 */

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/event_bus_model/overlay_web_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/create_room/create_param_dialog.dart';
import 'package:fb_live_flutter/live/pages/live_room/dialog/more_dialog.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/live/shop_widget.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'gifts_record_widget.dart';

enum BtnType { chat, gift, share, close, param, more, picture }

typedef ButtonClickBlock = void Function(int index, String text);
typedef SendClickBlock = void Function(String text); //弹幕回调

/// 【2021 11.19】【APP】直播间下栏图标大小
///
/// 怎么做【逻辑】？
/// 1。需要主播端和观众端统一调整；
/// 2。注意web端的；
///
class AnchorBottomView extends StatefulWidget {
  final ButtonClickBlock? buttonClickBlock;
  final SendClickBlock? sendClickBlock;
  final String? roomId;
  final String? shareType; //分享类型 0不分享 1分享
  final bool? isStartLive; //是否显示关闭直播的按钮 （拉流成功后再显示关闭按钮）
  final bool isExternal;
  final LiveInterface liveBloc;
  final LiveShopInterface liveShop;
  final LiveMoreInterface? more;
  final GoodsLogic goodsLogic;

  const AnchorBottomView({
    Key? key,
    this.buttonClickBlock,
    this.roomId,
    this.isStartLive,
    this.shareType,
    this.sendClickBlock,
    this.isExternal = false,
    required this.liveBloc,
    required this.liveShop,
    required this.goodsLogic,
    this.more,
  }) : super(key: key);

  @override
  _AnchorBottomViewState createState() => _AnchorBottomViewState();
}

class _AnchorBottomViewState extends State<AnchorBottomView> {
  ButtonClickBlock? buttonClickBlock;
  TextEditingController? _controller;

  FocusNode? _focusNode;

  /// 【2021 11.19】新版
  Color itemBgColor = const Color(0xff000000).withOpacity(0.25);

  RoomInfon get roomInfoObject {
    return widget.liveBloc.getRoomInfoObject!;
  }

  @override
  void dispose() {
    _controller!.dispose();
    _focusNode!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = TextEditingController();
    _focusNode = FocusNode();
    buttonClickBlock = widget.buttonClickBlock;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FrameSize.winWidth() - 30.px,
      child: kIsWeb
          ? Row(children: [
              Expanded(
                child: _textView(context),
              ),
              SizedBox(width: FrameSize.px(11)),
              clickBtn(context, BtnType.gift),
              SizedBox(width: FrameSize.px(8)),
              clickBtn(context, BtnType.picture),
              SizedBox(width: FrameSize.px(8)),
              clickBtn(context, BtnType.share),
              SizedBox(width: FrameSize.px(8)),
              Offstage(
                offstage: widget.isStartLive!,
                child: clickBtn(context, BtnType.close),
              )
            ])
          : Row(
              children: [
                ShopWidget(
                  widget.liveShop,
                  widget.liveBloc,
                  margin: EdgeInsets.only(right: 14.px),
                  goodsLogic: widget.goodsLogic,
                ),
                clickBtn(context, BtnType.chat),
                Space(width: 10.px),
                if (widget.isExternal) clickBtn(context, BtnType.param),
                const Spacer(),
                clickBtn(context, BtnType.gift),
                Space(width: 10.px),
                Offstage(
                  offstage: widget.isStartLive!,
                  child: clickBtn(context, BtnType.close),
                ),
                Space(width: 10.px),
                clickBtn(context, BtnType.more),
              ],
            ),
    );
  }

  Future action(BtnType type) async {
    if (type == BtnType.share) {
      // 分享弹窗
      final bool canWatchOutSide = widget.shareType == "1";
      final FBShareContent fbShareContent = FBShareContent(
        type: ShareType.webLive,
        roomId: widget.roomId!,
        canWatchOutside: canWatchOutSide,
        guildId: roomInfoObject.serverId,
        channelId: roomInfoObject.channelId,
        coverUrl: roomInfoObject.avatarUrl!,
        anchorName: roomInfoObject.nickName!,
      );
      LiveLogUp.audioShare(roomInfoObject);
      await fbApi.showShareLinkPopUp(context, fbShareContent);
    } else if (type == BtnType.gift) {
      await showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) {
            return GiftsRecord(
              roomId: widget.roomId,
              roomInfoObject: roomInfoObject,
            );
          });
    } else if (type == BtnType.chat) {
      fbApi.showEmojiKeyboard(context, onSendText: (text) {
        buttonClickBlock!(0, text);
      });
    } else if (type == BtnType.param) {
      await createParamDialog(
          context, widget.liveBloc.liveValueModel!.obsModel);
    } else if (type == BtnType.more) {
      await moreDialog(context, widget.more, widget.isExternal,
              widget.liveBloc.liveValueModel!)
          .then((value) {
        if (value is int && value == 0) {
          _flipCamera();
        } else if (value is int && value == 1) {
          widget.liveBloc.liveValueModel!.isMirror =
              !widget.liveBloc.liveValueModel!.isMirror;
          widget.liveBloc.checkMirrorMode();
        } else if (value is int && value == 2) {
          share();
        }
      });
    } else if (type == BtnType.picture) {
      if (kIsWeb) {
        EventBusManager.eventBus.fire(OverlayWebModel());
      }
    } else {
      buttonClickBlock!(3, "");
    }
  }

  //主播界面底部按钮
  Widget clickBtn(BuildContext context, BtnType type) {
    return ClickEvent(
      onTap: () async {
        await action(type);
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: FrameSize.px(36),
          maxHeight: FrameSize.px(36),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: itemBgColor,
          borderRadius: BorderRadius.circular(FrameSize.px(21)),
        ),
        child: UnconstrainedBox(
          child: SizedBox(
            width: 24.px,
            height: 24.px,
            child: type == BtnType.chat
                ? Image.asset("assets/live/LiveRoom/chat_anchor.png")
                : (type == BtnType.gift
                    ? Image.asset("assets/live/LiveRoom/gift_btn.png")
                    : (type == BtnType.share
                        ? Image.asset("assets/live/LiveRoom/live_share.png")
                        : type == BtnType.param
                            ? Image.asset('assets/live/main/ic_settings.png',
                                color: Colors.white)
                            : type == BtnType.more
                                ? Image.asset('assets/live/main/ic_more.png',
                                    color: Colors.white)
                                : type == BtnType.picture
                                    ? Image.asset(
                                        'assets/live/main/web_live_picture.png')
                                    : Image.asset(
                                        "assets/live/LiveRoom/close_anchor.png"))),
          ),
        ),
      ),
    );
  }

  /*
  * 调用分享
  * */
  void share() {
    // 分享弹窗
    final bool canWatchOutSide = widget.shareType == "1";
    final FBShareContent fbShareContent = FBShareContent(
      type: ShareType.webLive,
      roomId: widget.roomId!,
      canWatchOutside: canWatchOutSide,
      guildId: roomInfoObject.serverId,
      channelId: roomInfoObject.channelId,
      coverUrl: roomInfoObject.avatarUrl!,
      anchorName: roomInfoObject.nickName!,
    );
    LiveLogUp.audioShare(roomInfoObject);
    fbApi.showShareLinkPopUp(context, fbShareContent);
  }

  /*
  * 摄像头翻转
  * */
  void _flipCamera() {
    widget.liveBloc.liveValueModel!.useFrontCamera =
        !widget.liveBloc.liveValueModel!.useFrontCamera;
    if (!widget.liveBloc.liveValueModel!.useFrontCamera) {
      //非镜像
      widget.liveBloc.liveValueModel!.isMirror = false;
      ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);
    } else {
      widget.liveBloc.liveValueModel!.isMirror = true;
      ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
    }
    ZegoExpressEngine.instance
        .useFrontCamera(widget.liveBloc.liveValueModel!.useFrontCamera);
  }

  //会话框
  Widget _textView(BuildContext context) {
    return Container(
      height: FrameSize.px(36),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(FrameSize.px(25)),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(left: FrameSize.px(15), right: FrameSize.px(15)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "聊一聊",
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      fbApi.showEmojiKeyboard(
                        context,
                        inputController: _controller,
                        onSendText: (text) {},
                      );
                    },
                    child:
                        Image.asset("assets/live/LiveRoom/keyboard_emoji.png"),
                  ),
                ),
                onSubmitted: (text) {
                  widget.sendClickBlock!(text);
                  _controller!.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
