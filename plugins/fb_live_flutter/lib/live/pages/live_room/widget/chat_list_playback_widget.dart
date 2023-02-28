import 'dart:convert';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../bloc_model/chat_list_unread_bloc_model.dart';
import '../../../bloc_model/fb_refresh_widget_bloc_model.dart';
import '../../../utils/ui/frame_size.dart';
import 'expanded_viewport.dart';

class ChartListPlayBackView extends StatefulWidget {
  final String? tips;
  final List? chatList;
  final bool? isOverlayViewPush;
  final bool isScreenRotation;
  final VoidCallback? onLoading;
  final RefreshController? refreshController;
  final RoomInfon? roomInfoObject;

  const ChartListPlayBackView(
      {Key? key,
      this.chatList,
      this.tips,
      this.onLoading,
      this.refreshController,
      this.isOverlayViewPush,
      this.roomInfoObject,
      this.isScreenRotation = false})
      : super(key: key);

  @override
  _ChartListPlayBackViewState createState() => _ChartListPlayBackViewState();
}

class _ChartListPlayBackViewState extends State<ChartListPlayBackView> {
  late ScrollController _controller;
  bool userDrag = false;
  int dragCount = 0;
  bool showMask = true;

  List? _reversSendChatList;

  @override
  void initState() {
    _controller = ScrollController();

    if (widget.chatList!.length > 200) {
      widget.chatList!.removeRange(0, widget.chatList!.length - 200);
    }
    if (widget.isOverlayViewPush!) {
      dragCount = widget.chatList!.length;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.hasClients) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        if (!userDrag) {
          final double dy =
              _controller.position.extentAfter + _controller.offset;
          _controller.jumpTo(dy);
        }
      });
      if (_controller.position.extentAfter <= 1) {
        dragCount = widget.chatList!.length;
      }
    }
    return BlocProvider<ChatListUnreadBlocModel>(
      create: (context) => ChatListUnreadBlocModel(RefreshState.none),
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: FrameSize.px(308),

              /// IM信息行多出的以及最上面的IM信息渐变问题，这个发送的消息和礼物消息统一做成圆角的，不要方圆的。以及算一下IM信息只显示7条算出文字带动这个IM信息框的大小
              /// 观众多出的IM
              maxHeight: FrameSize.px(!widget.isScreenRotation ? 207 : 150),
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FrameSize.px(6))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FrameSize.px(6)),
              child: kIsWeb
                  ? const Text('暂不支持web')
                  : SmartRefresher(
                      controller: widget.refreshController!,
                      onLoading: widget.onLoading,
                      enablePullUp: true,
                      enablePullDown: false,
                      footer: NullFooterView(),
                      child: Scrollable(
                        axisDirection: AxisDirection.up,
                        viewportBuilder: (context, offset) {
                          return ExpandedViewport(
                            offset: offset as ScrollPosition,
                            axisDirection: AxisDirection.up,
                            slivers: <Widget>[
                              SliverToBoxAdapter(
                                child: (widget.tips == null ||
                                        widget.tips == "")
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
                                  childCount: widget.chatList!.length,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemSeparatedList(BuildContext context, int index) {
    _reversSendChatList = widget.chatList;
    return Container(
      constraints: BoxConstraints(maxWidth: FrameSize.px(279)),
      padding: EdgeInsets.fromLTRB(

          /// IM信息行多出的以及最上面的IM信息渐变问题，这个发送的消息和礼物消息统一做成圆角的，不要方圆的。以及算一下IM信息只显示7条算出文字带动这个IM信息框的大小
          /// 观众多出的IM
          FrameSize.px(8),
          FrameSize.px(3),
          FrameSize.px(8),
          FrameSize.px(3)),
      decoration: BoxDecoration(
        color: const Color(0x8C000000).withOpacity(0.25),
        borderRadius: BorderRadius.circular(FrameSize.px(15)), //
      ),
      child: _reversSendChatList![index]["content"]
                  .toString()
                  .contains("giftId") &&
              _reversSendChatList![index]["content"]
                  .toString()
                  .contains("giftQt")
          ? _giftsRichText(context, index)
          : _userChatRichText(context, index),
    );
  }

  //用户发送消息
  Widget _userChatRichText(BuildContext context, int index) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: "${_reversSendChatList![index]["author"]["nickname"]}:",
              style: TextStyle(
                  color: const Color(0xFF8CE7FF),
                  fontSize: FrameSize.px(14),
                  fontWeight: FontWeight.w600),
              recognizer: ClickEvenGestureRecognizer()
                ..onTap = () {
                  FbApiModel.showUserInfoPopUp(
                    context,
                    _reversSendChatList![index]["user_id"],
                    widget.roomInfoObject?.serverId,
                  );
                }),
          const WidgetSpan(child: SizedBox(width: 5)),
          fbApi.buildEmojiText(
            context,
            json.decode(_reversSendChatList![index]["content"])['content'],
            textStyle: TextStyle(
                color: Colors.white,
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }

  //礼物消息
  Widget _giftsRichText(BuildContext context, int index) {
    final _nickName = _reversSendChatList![index]["author"]["nickname"];
    final _userId = _reversSendChatList![index]["user_id"];

    final Map contentMap = json.decode(_reversSendChatList![index]['content']);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _nickName,
            style: TextStyle(
                color: const Color(0xFF8CE7FF),
                fontSize: FrameSize.px(14),
                fontWeight: FontWeight.w600),
            recognizer: ClickEvenGestureRecognizer()
              ..onTap = () {
                FbApiModel.showUserInfoPopUp(
                    context, _userId, widget.roomInfoObject?.serverId);
              },
          ),
          TextSpan(
            text: " 送出${contentMap["giftName"]} ",
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
              "${contentMap["giftImgUrl"]}",
              width: FrameSize.px(16),
              height: FrameSize.px(16),
              fit: BoxFit.cover,
            ),
          )),
          TextSpan(
            text: " x${contentMap["giftQt"]}",
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
  }
}
