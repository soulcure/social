import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/playback_bloc.dart';
import 'package:fb_live_flutter/live/bloc_model/chat_list_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/screen_clear_bloc_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/playback/playback_bus.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/anchor_top_widgt.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/chat_list_playback_widget.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_new_page.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaybackNormalPage extends StatefulWidget {
  final RoomListModel roomModel;
  final bool isFromLive;
  final bool isFromList;
  final bool isNeedWakelock;

  const PlaybackNormalPage(
    this.roomModel, {
    this.isFromLive = false,
    this.isFromList = true,
    this.isNeedWakelock = true,
  });

  @override
  PlaybackNormalPageState createState() => PlaybackNormalPageState();
}

class PlaybackNormalPageState extends State<PlaybackNormalPage> {
  final PlaybackBloc _playbackBloc = PlaybackBloc();

  @override
  void initState() {
    super.initState();
    _playbackBloc.init(this, widget.roomModel.serverId);
  }

  Widget body() {
    final double paddingB = FrameSize.padBotH() + (24 + 16).px;
    return MyScaffold(
      overlayStyle: SystemUiOverlayStyle.light,
      body: Stack(
        children: [
          PlaybackPlayWidget(widget.roomModel),
          Positioned(
            bottom: paddingB,
            child: GestureDetector(
              onTap: () {
                playBackBus.fire(PlayBackEvenModel());
              },
              child: SizedBox(
                width: FrameSize.winWidth(),
                height: FrameSize.winHeight() - paddingB,
                child: PageView(
                  children: [
                    SizedBox(
                      width: FrameSize.winWidth(),
                      height: FrameSize.winHeight() - paddingB,
                      child: Stack(
                        children: [
                          Positioned(
                            top: !_playbackBloc.isScreenRotation
                                ? FrameSize.padTopH() + FrameSize.px(8)
                                : FrameSize.px(8),
                            left: FrameSize.px(12),
                            right: FrameSize.px(12),
                            child: Row(
                              children: [
                                StatefulBuilder(
                                    key: _playbackBloc.topKey,
                                    builder: (context, _) {
                                      return AnchorTopView(
                                        imageUrl: widget.roomModel.avatarUrl ??
                                            _playbackBloc
                                                .roomInfoObject?.avatarUrl,
                                        anchorName:
                                            _playbackBloc.thisAnchorName,
                                        anchorId: widget.roomModel.anchorId,
                                        serverId: widget.roomModel.serverId,
                                        likesCount: widget.roomModel.watchNum ??
                                            widget.roomModel.audienceCount,
                                        isPlayBack: true,
                                        isReplace: true,
                                        onShowDialog: () {
                                          _playbackBloc.isShowDialog = true;
                                        },
                                        onCancelDialog: () {
                                          _playbackBloc.isShowDialog = false;
                                        },
                                      );
                                    }),
                                const Spacer(),
                                ClickEvent(
                                  onTap: () async {
                                    final FBShareContent fbShareContent =
                                        FBShareContent(
                                      type: ShareType.playback,
                                      roomId: widget.roomModel.roomId!,
                                      canWatchOutside: true,
                                      guildId: _playbackBloc
                                              .roomInfoObject?.serverId ??
                                          fbApi.getCurrentChannel()!.guildId,
                                      channelId: _playbackBloc
                                              .roomInfoObject?.channelId ??
                                          fbApi.getCurrentChannel()!.id,
                                      anchorName: _playbackBloc.thisAnchorName!,
                                      coverUrl: _playbackBloc
                                              .roomInfoObject?.roomLogo ??
                                          '',
                                    );
                                    await fbApi.showShareLinkPopUp(
                                        context, fbShareContent);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 12.px),
                                    child: Image.asset(
                                        "assets/live/main/playback_share.png",
                                        width: 32.px,
                                        height: 32.px),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 5.px),
                                    child: Image.asset(
                                        "assets/live/main/playback_close.png",
                                        width: 32.px,
                                        height: 32.px),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BlocBuilder<ScreenClearBlocModel, bool>(
                            builder: (context, clearState) {
                              return Offstage(
                                offstage: clearState,
                                child: _bottomViews(context),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _playbackBloc.context = context;
    return MultiBlocProvider(
      providers: _playbackBloc.providers,
      child: BlocBuilder(
        bloc: _playbackBloc,
        builder: (_, __) {
          return body();
        },
      ),
    );
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
          if (!_playbackBloc.isScreenRotation)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chartWidget(), //评论区
                // btnWidget(), //操作区
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                chartWidget(),
                // btnWidget(),
              ],
            ),
        ],
      ),
    );
  }

  //底部评论区
  Widget chartWidget() {
    return Column(
      children: [
        SizedBox(height: FrameSize.px(5)),
        BlocBuilder<ChatListBlocModel, Map?>(
          bloc: _playbackBloc.chatListBlocModel,
          builder: (context, msgMap) {
            return ChartListPlayBackView(
              isOverlayViewPush: false,
              isScreenRotation: _playbackBloc.isScreenRotation,
              chatList: _playbackBloc.data,
              refreshController: _playbackBloc.refreshController,
              onLoading: _playbackBloc.getData,
              roomInfoObject: _playbackBloc.roomInfoObject,
            );
          },
        ),
        SizedBox(height: FrameSize.px(5)),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _playbackBloc.close();
  }
}
