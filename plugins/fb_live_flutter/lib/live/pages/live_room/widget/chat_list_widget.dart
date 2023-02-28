import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/event_bus_model/screen_rotation_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc_model/chat_list_unread_bloc_model.dart';
import '../../../bloc_model/fb_refresh_widget_bloc_model.dart';
import '../../../utils/ui/frame_size.dart';

class ChartListView extends StatefulWidget {
  final String? tips;
  final bool? isOverlayViewPush;
  final bool isScreenRotation;
  final bool isPlayback;
  final RoomInfon? roomInfoObject;

  final LiveInterface bloc;

  const ChartListView({
    Key? key,
    this.tips,
    this.isOverlayViewPush,
    this.isScreenRotation = false,
    this.isPlayback = false,
    this.roomInfoObject,
    required this.bloc,
  }) : super(key: key);

  @override
  _ChartListViewState createState() => _ChartListViewState();
}

class _ChartListViewState extends State<ChartListView>
    with AutomaticKeepAliveClientMixin {
  ScrollController? _controller;
  bool userDrag = false;
  int dragCount = 0;
  bool showMask = true;
  late ChatListUnreadBlocModel _chatListUnreadBlocModel;

  StreamSubscription? _screenSubs;

  late List _reversSendChatList;

  @override
  void initState() {
    _controller = ScrollController();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final double dy = _controller!.position.extentAfter + _controller!.offset;

      _controller!.jumpTo(dy);

      dragCount = widget.bloc.liveValueModel!.chatList.length;
      setState(() {});
    });

    if (widget.bloc.liveValueModel!.chatList.length > 200) {
      widget.bloc.liveValueModel!.chatList
          .removeRange(0, widget.bloc.liveValueModel!.chatList.length - 200);
    }
    if (widget.isOverlayViewPush!) {
      dragCount = widget.bloc.liveValueModel!.chatList.length;
    }

    _screenSubs = rotationEventBus.on<ScreenRotationEvent>().listen((event) {});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_controller!.hasClients) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        if (!userDrag) {
          final double dy =
              _controller!.position.extentAfter + _controller!.offset;
          _controller!.jumpTo(dy);
        }
      });
      if (_controller!.position.extentAfter <= 1) {
        dragCount = widget.bloc.liveValueModel!.chatList.length;
      }
    }
    return BlocProvider<ChatListUnreadBlocModel>(
      create: (context) =>
          _chatListUnreadBlocModel = ChatListUnreadBlocModel(RefreshState.none),
      child: NotificationListener(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            if (!userDrag) {
              userDrag = true;
              dragCount = widget.bloc.liveValueModel!.chatList.length;
              _chatListUnreadBlocModel.add(true);
            } else {
              if (_controller!.position.extentAfter <= 1) {
                userDrag = false;
                dragCount = widget.bloc.liveValueModel!.chatList.length;
                _chatListUnreadBlocModel.add(true);
              }
            }
          }

          return true;
        },
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: FrameSize.px(308),

                /// IM信息行多出的以及最上面的IM信息渐变问题，这个发送的消息和礼物消息统一做成圆角的，不要方圆的。以及算一下IM信息只显示7条算出文字带动这个IM信息框的大小
                /// 观众多出的IM
                maxHeight: FrameSize.px(!widget.isScreenRotation ? 203 : 123.5),
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FrameSize.px(6))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FrameSize.px(6)),
                child: kIsWeb
                    ? CustomScrollView(
                        controller: _controller,
                        shrinkWrap: true,
                        slivers: [
                          SliverToBoxAdapter(
                            child: (widget.tips == null || widget.tips == "")
                                ? Container()
                                : Container(
                                    padding: EdgeInsets.fromLTRB(
                                        FrameSize.px(10),
                                        FrameSize.px(3),
                                        FrameSize.px(10),
                                        FrameSize.px(3)),
                                    decoration: BoxDecoration(
                                      color: const Color(0x8C000000)
                                          .withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(
                                          FrameSize.px(6)),
                                    ),
                                    child: Text(widget.tips!,
                                        style: TextStyle(
                                            color: const Color(0xFFA8E4F8),
                                            fontSize: FrameSize.px(14),
                                            fontWeight: FontWeight.w500)),
                                  ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Container(
                                  key: GlobalKey(),
                                  padding: EdgeInsets.only(
                                    top: FrameSize.px(3),
                                  ),

                                  /// IM信息行多出的以及最上面的IM信息渐变问题，这个发送的消息和礼物消息统一做成圆角的，不要方圆的。以及算一下IM信息只显示7条算出文字带动这个IM信息框的大小
                                  /// 观众多出的IM
                                  height: (208 / 7).px,
                                  child: _itemSeparatedList(context, index),
                                );
                              },
                              childCount:
                                  widget.bloc.liveValueModel!.chatList.length,
                            ),
                          ),
                        ],
                      )
                    : FadingEdgeScrollView.fromScrollView(
                        gradientFractionOnStart: 0.6,
                        child: CustomScrollView(
                          controller: _controller,
                          shrinkWrap: true,
                          slivers: [
                            SliverToBoxAdapter(
                              child: (widget.tips == null || widget.tips == "")
                                  ? Container()
                                  : Container(
                                      padding: EdgeInsets.fromLTRB(
                                          FrameSize.px(10),
                                          FrameSize.px(3),
                                          FrameSize.px(10),
                                          FrameSize.px(3)),
                                      decoration: BoxDecoration(
                                        /// https://idreamsky.feishu.cn/docs/doccn3YZewVeG2ks6oG0n1tbM4f#AC8RD8
                                        /// 4. 直播间欢迎内容背景颜色、圆角都不符合设计稿（内容单行的时候也应该是圆角不是方圆）
                                        color: const Color(0x8C000000)
                                            .withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(
                                            FrameSize.px(15)),
                                      ),
                                      child: Text(widget.tips!,
                                          style: TextStyle(
                                              color: const Color(0xFFA8E4F8),
                                              fontSize: FrameSize.px(14),
                                              fontWeight: FontWeight.w500)),
                                    ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return Container(
                                    padding: EdgeInsets.only(
                                      top: FrameSize.px(3),
                                    ),
                                    child: Row(
                                      children: [
                                        _itemSeparatedList(context, index),
                                        Expanded(
                                          child: Container(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount:
                                    widget.bloc.liveValueModel!.chatList.length,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            BlocBuilder<ChatListUnreadBlocModel, RefreshState?>(
              builder: (context, refresh) {
                return widget.bloc.liveValueModel!.chatList.length -
                            dragCount <=
                        0
                    ? Container()
                    : Positioned(
                        bottom: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () {
                            try {
                              userDrag = false;
                              dragCount =
                                  widget.bloc.liveValueModel!.chatList.length;
                              _chatListUnreadBlocModel.add(true);

                              WidgetsBinding.instance!
                                  .addPostFrameCallback((timeStamp) async {
                                final double dy =
                                    _controller!.position.extentAfter +
                                        _controller!.offset;
                                _controller!.jumpTo(dy);
                              });
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(100)),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              "↓${widget.bloc.liveValueModel!.chatList.length - dragCount > 99 ? "99+" : widget.bloc.liveValueModel!.chatList.length - dragCount}条新消息",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemSeparatedList(BuildContext context, int index) {
    _reversSendChatList = widget.bloc.liveValueModel!.chatList;
    final resultItem = widget.isPlayback
        ? json.decode(_reversSendChatList[index]['content'])
        : _reversSendChatList[index];

    return Container(
      constraints: BoxConstraints(maxWidth: FrameSize.px(279)),
      padding: EdgeInsets.fromLTRB(
          FrameSize.px(8), FrameSize.px(3), FrameSize.px(8), FrameSize.px(3)),
      decoration: BoxDecoration(
        color: const Color(0x8C000000).withOpacity(0.25),
        borderRadius: BorderRadius.circular(FrameSize.px(15)), //
      ),
      child: resultItem["type"] == "user_chat"
          ? _userChatRichText(context, index)
          : (resultItem["type"] == "give_gifts"
              ? _giftsRichText(context, index)
              : _userComeRichText(context, index)),
    );
  }

  //用户发送消息
  Widget _userChatRichText(BuildContext context, int index) {
    final resultItem = widget.isPlayback
        ? json.decode(_reversSendChatList[index]['content'])
        : _reversSendChatList[index];

    final bool isUp = resultItem["text"] == "为主播点赞了";

    final bool isBean = resultItem["user"] is FBUserInfo;
    final user = resultItem["user"];
    final userName = isBean ? user?.name : user["name"];
    final userId = isBean ? user?.userId : user["userId"];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: isUp ? "$userName" : "$userName:",
              style: TextStyle(
                  color: const Color(0xFF8CE7FF),
                  fontSize: FrameSize.px(14),
                  fontWeight: FontWeight.w600),
              recognizer: ClickEvenGestureRecognizer()
                ..onTap = () {
                  showUserInfoPopUp(
                      context, userId, widget.roomInfoObject?.serverId);
                }),
          const WidgetSpan(child: SizedBox(width: 5)),
          fbApi.buildEmojiText(
            context,
            isUp ? "为主播点赞了" : resultItem["text"],
            textStyle: TextStyle(
                color: isUp ? Colors.white.withOpacity(0.75) : Colors.white,
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }

  //用户进入房间消息
  Widget _userComeRichText(BuildContext context, int index) {
    final resultItem = widget.isPlayback
        ? json.decode(_reversSendChatList[index]['content'])
        : _reversSendChatList[index];
    final bool isBean = resultItem["user"] is FBUserInfo;
    final user = resultItem["user"];
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: isBean ? user?.name : user["name"],
            style: TextStyle(
                color: const Color(0xFF8CE7FF),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
            recognizer: ClickEvenGestureRecognizer()
              ..onTap = () {
                showUserInfoPopUp(
                    context,
                    isBean ? user?.userId : user["userId"],
                    widget.roomInfoObject?.serverId);
              },
          ),
          TextSpan(
            text: " 来了",
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future showUserInfoPopUp(
      BuildContext context, String? userId, String? guildId) async {
    final contextValue = await widget.bloc.rotateScreenExec(context);
    if (contextValue == null) {
      return;
    }

    await FbApiModel.showUserInfoPopUp(
      contextValue,
      userId,
      guildId,
    );
  }

  //礼物消息
  Widget _giftsRichText(BuildContext context, int index) {
    final resultItem = widget.isPlayback
        ? json.decode(_reversSendChatList[index]['content'])
        : _reversSendChatList[index];

    final bool isBean = resultItem["user"] is FBUserInfo;
    final user = resultItem["user"];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: isBean ? user?.name : user["name"],
            style: TextStyle(
                color: const Color(0xFF8CE7FF),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
            recognizer: ClickEvenGestureRecognizer()
              ..onTap = () {
                showUserInfoPopUp(
                    context,
                    isBean ? user?.userId : user["userId"],
                    widget.roomInfoObject?.serverId);
              },
          ),
          TextSpan(
            text: " 送出${resultItem["text"]["giftName"]} ",
            style: TextStyle(
                color: const Color(0xFFFACE15),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
          ),
          WidgetSpan(
              child: Container(
            alignment: Alignment.center,
            width: FrameSize.px(20),
            height: FrameSize.px(20),
            child: Image.network(
              "${resultItem["text"]["giftImgUrl"]}",
              width: FrameSize.px(16),
              height: FrameSize.px(16),
              fit: BoxFit.cover,
            ),
          )),
          TextSpan(
            text: " x${resultItem["text"]["giftQt"]}",
            style: TextStyle(
                color: const Color(0xFFFACE15),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _screenSubs?.cancel();
  }

  @override
  bool get wantKeepAlive => true;
}
