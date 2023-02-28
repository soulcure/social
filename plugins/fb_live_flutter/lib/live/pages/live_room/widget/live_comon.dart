import 'dart:collection';

import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/bloc_model/chat_list_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/emoji_keyborad_block_model.dart';
import 'package:fb_live_flutter/live/bloc_model/fb_refresh_widget_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/gift_move_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/room_bottom_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/screen_clear_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/user_join_live_room_model.dart';
import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_live_card.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/anchor_bottom_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/audiences_bottom_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/chat_list_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/gifts_give_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/tips_login_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../fb_live_flutter.dart';

class LiveGiftCommon extends Positioned {
  final Function(GiveGiftModel?)? animationCompleteGiftsOne;
  final Function(GiveGiftModel?)? animationCompleteGiftsTwo;
  final Function(GiveGiftModel?)? animationCompleteGiftsThree;
  final VoidCallback? animationCompeteTips;
  final Widget bottomViews;

  LiveGiftCommon({
    required this.animationCompleteGiftsOne,
    required this.animationCompleteGiftsTwo,
    required this.animationCompleteGiftsThree,
    required this.animationCompeteTips,
    required this.bottomViews,
  }) : super(
          bottom: FrameSize.padBotH(),
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    left: FrameSize.px(15), right: FrameSize.px(15)),
                child: Column(
                  children: [
                    SizedBox(
                      height: FrameSize.px(42) * 3 + 2 * FrameSize.px(5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          BlocBuilder<GiftMoveBlocModel, GiveGiftModel?>(
                            buildWhen: (previous, current) {
                              return true;
                            },
                            builder: (context, giveGiftModel) {
                              if (giveGiftModel == null) {
                                return Container();
                              }
                              return GiftsGiveView(
                                giveGiftModel: giveGiftModel,
                                count: giveGiftModel.count,
                                animationComplete: animationCompleteGiftsOne,
                                refreshListener: (Function(GiveGiftModel)
                                    refreshCallBack) {},
                              );
                            },
                          ), //展示有bug
                          Padding(
                            padding: EdgeInsets.only(
                              top: FrameSize.px(5),
                            ),
                            child: Container(),
                          ),
                          BlocBuilder<GiftMoveBlocModel2, GiveGiftModel?>(
                            buildWhen: (previous, current) {
                              return true;
                            },
                            builder: (context, giveGiftModel) {
                              if (giveGiftModel == null) {
                                return Container();
                              }
                              return GiftsGiveView(
                                giveGiftModel: giveGiftModel,
                                count: giveGiftModel.count,
                                animationComplete: animationCompleteGiftsTwo,
                                refreshListener: (Function(GiveGiftModel)
                                    refreshCallBack) {},
                              );
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: FrameSize.px(5),
                            ),
                            child: Container(),
                          ),

                          BlocBuilder<GiftMoveBlocModel3, GiveGiftModel?>(
                            buildWhen: (previous, current) {
                              return true;
                            },
                            builder: (context, giveGiftModel) {
                              if (giveGiftModel == null) {
                                return Container();
                              }
                              return GiftsGiveView(
                                giveGiftModel: giveGiftModel,
                                count: giveGiftModel.count,
                                animationComplete: animationCompleteGiftsThree,
                                refreshListener: (Function(GiveGiftModel)
                                    refreshCallBack) {},
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: FrameSize.px(5)),
                    BlocBuilder<UserJoinLiveRoomModel, FBUserInfo?>(
                      builder: (context, joinedUserInfo) {
                        return TipsLoginView(
                          userInfo: joinedUserInfo,
                          animationCompete: animationCompeteTips,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Space(height: 8.px),
              BlocBuilder<ScreenClearBlocModel, bool>(
                builder: (context, clearState) {
                  return Offstage(
                    offstage: clearState,
                    child: bottomViews,
                  );
                },
              ),
            ],
          ),
        );
}

class LiveWidgetListCommon<T> extends StatelessWidget {
  final bool isAnchor;
  final Stream<List<Widget>> stream;

  const LiveWidgetListCommon({
    Key? key,
    required this.isAnchor,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAnchor)
      return Container();
    else
      return StreamBuilder<List<Widget>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return Positioned(
              right: FrameSize.px(16),
              bottom: FrameSize.px(50),
              child: SizedBox(
                width: 42,
                height: 240,
                child: Stack(
                  children: snapshot.data!.map<Widget>((f) => f).toList(),
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      );
  }
}

class BottomViewsCommon extends StatelessWidget {
  final bool isScreenRotation;
  final LiveInterface bloc;
  final PushGoodsLiveRoomModel? pushGoodsLiveRoomModel;
  final Queue<GoodsPushModel> goodsQueue;
  final LiveMoreInterface? more;
  final LiveShopInterface liveShop;
  final String roomId;
  final bool isExternal;
  final ButtonClickBlock? buttonClickBlock;
  final SendClickBlock? fbApiSendLiveMsg;
  final UpLikeClickBlock? upLikeClickBlock;
  final GoodsLogic goodsLogic;

  const BottomViewsCommon({
    Key? key,
    required this.isScreenRotation,
    required this.bloc,
    required this.pushGoodsLiveRoomModel,
    required this.goodsQueue,
    required this.more,
    required this.liveShop,
    required this.roomId,
    required this.isExternal,
    required this.buttonClickBlock,
    required this.fbApiSendLiveMsg,
    required this.upLikeClickBlock,
    required this.goodsLogic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _bottomViews(context);
  }

  //底部view
  Widget _bottomViews(BuildContext context) {
    return Container(
      width: FrameSize.winWidth(),
      padding: EdgeInsets.only(
          left: FrameSize.px(15),
          right: FrameSize.px(15),
          bottom: FrameSize.px(16)),
      child: Stack(
        children: [
          if (!isScreenRotation)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chartWidget(), //评论区
                goodsLiveCardWidget(), // 直播带货推送的卡片
                btnWidget(), //操作区
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: chartWidget()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    goodsLiveCardWidget(), // 直播带货推送的卡片
                    btnWidget(),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  //底部评论区
  Widget goodsLiveCardWidget() {
    return BlocBuilder<PushGoodsLiveRoomModel, GoodsPushModel?>(
      builder: (context, pushModel) {
        final bool goodsQueueLength = goodsQueue.isNotEmpty;
        if (!goodsQueueLength) {
          return Container();
        }
        final GoodsPushModel lastModel = goodsQueue.last;
        if (lastModel.countdown! > 0) {
          return GoodsLiveCard(pushGoodsLiveRoomModel, lastModel, bloc);
        }
        return Container();
      },
    );
  }

  Widget chartWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: FrameSize.px(5)),
        BlocBuilder<ChatListBlocModel, Map?>(
          builder: (context, msgMap) {
            return ChartListView(
              isOverlayViewPush: bloc.isOverlayViewPush,
              tips: bloc.getRoomInfoObject?.tips,
              isScreenRotation: isScreenRotation,
              roomInfoObject: bloc.getRoomInfoObject,
              bloc: bloc,
            );
          },
        ),
        SizedBox(height: FrameSize.px(5)),
      ],
    );
  }

  //底部操作区
  Widget btnWidget() {
    return Row(
      children: [
        BlocBuilder<EmojiKeyBoradBlocModel, double?>(
          builder: (context, keyboardHeight) {
            final _keyboardHeight = keyboardHeight ?? 0;
            final double _keyHeight = _keyboardHeight - FrameSize.padBotH();
            final double _keyHeightResult = _keyHeight < 0 ? 0 : _keyHeight;
            return SizedBox(
              height: _keyHeightResult,
            );
          },
        ),
        SizedBox(height: FrameSize.px(12)),
        BlocBuilder<RoomBottomBlocModel, RefreshState?>(
          buildWhen: (previous, current) {
            return true;
          },
          builder: (context, value) {
            if (bloc.isAnchor) {
              return AnchorBottomView(
                liveBloc: bloc,
                more: more,
                liveShop: liveShop,
                isStartLive: bloc.isStartLive,
                roomId: roomId,
                shareType: bloc.shareType.toString(),
                buttonClickBlock: buttonClickBlock,
                isExternal: isExternal,
                goodsLogic: goodsLogic,
              );
            }
            return AudiencesBottomView(
              roomId: roomId,
              roomInfoObject: bloc.getRoomInfoObject,
              isScreenRotation: isScreenRotation,
              shareType: bloc.shareType.toString(),
              liveBloc: bloc,
              liveShop: liveShop,
              // 发送弹幕消息
              sendClickBlock: fbApiSendLiveMsg,
              upLikeClickBlock: upLikeClickBlock,
              goodsLogic: goodsLogic,
            );
          },
        ),
        SizedBox(height: FrameSize.px(7)),
      ],
    );
  }
}
