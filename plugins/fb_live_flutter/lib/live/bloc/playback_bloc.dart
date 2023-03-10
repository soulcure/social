import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc_model/chat_list_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/emoji_keyborad_block_model.dart';
import 'package:fb_live_flutter/live/bloc_model/fb_refresh_widget_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/room_bottom_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/screen_clear_bloc_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/model/colse_room_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_normal_page.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/log/playback_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_preview_mode.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/window_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: implementation_imports
import 'package:flutter_bloc/src/bloc_provider.dart' as bloc_p;
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wakelock/wakelock.dart';

class PlaybackBloc extends BaseAppCubit<int> with BaseAppCubitState {
  String? serverId;

  PlaybackBloc() : super(0);

  RoomBottomBlocModel? _roomBottomBlocModel;
  ScreenClearBlocModel? _screenClearBlocModel;
  EmojiKeyBoradBlocModel? _emojiKeyBoardBlocModel;

  bool isAnchor = false;

  bool isScreenRotation = false;
  bool isShowDialog = false;

  final RefreshController refreshController = RefreshController();

  List<Map<String, dynamic>> data = [];

  ChatListBlocModel chatListBlocModel = ChatListBlocModel({});

  StreamSubscription? closeLBus;

  RoomInfon? roomInfoObject; //??????????????????

  GlobalKey topKey = GlobalKey();

  late State<PlaybackNormalPage> statePage;

  PlaybackNormalPage get widget {
    return statePage.widget;
  }

  BuildContext? context;

  BuildContext get thisContext {
    return context ?? statePage.context;
  }

  /// ?????????????????????????????????????????????????????????????????????????????????????????????????????????
  /// ??????????????????????????????????????????????????????
  bool get isSetWakelock {
    return statePage.widget.isNeedWakelock &&
        !RouteUtil.routeIsLive &&
        !RouteUtil.routeHasPreView &&
        !floatPreViewWindow.isHaveFloat &&
        !floatWindow.isHaveFloat;
  }

  Future init(State<PlaybackNormalPage> statePage, String? serverId) async {
    this.statePage = statePage;
    this.serverId = serverId;

    /// ????????????Wakelock
    /// ??????????????????????????????
    /// [2021 11.27]
    if (isSetWakelock) {
      fbApi.fbLogger.info('wakelock enable');
      await Wakelock.enable(); //??????????????????
    }
    await getRoomInfo();

    await playbackWatch();
    await onRefreshMsg();
    await getAudience();

    if (statePage.widget.isFromLive) {
      closeLBus = eventBus.on<LiveCloseEvent>().listen((event) {
        Get.back();
        if (isShowDialog) {
          RouteUtil.pop();
        }
      });
    }
  }

  List<bloc_p.BlocProviderSingleChildWidget> get providers {
    return [
      BlocProvider<ChatListBlocModel>(
        create: (context) {
          return chatListBlocModel = ChatListBlocModel(null);
        },
      ),
      BlocProvider<RoomBottomBlocModel>(
        create: (context) {
          return _roomBottomBlocModel = RoomBottomBlocModel(RefreshState.none);
        },
      ),
      BlocProvider<ScreenClearBlocModel>(
        create: (context) {
          return _screenClearBlocModel = ScreenClearBlocModel(false);
        },
      ),
      BlocProvider<EmojiKeyBoradBlocModel>(create: (context) {
        return _emojiKeyBoardBlocModel = EmojiKeyBoradBlocModel(0);
      }),
    ];
  }

  String? get thisAnchorName {
    return fbApi.getMarkName(
            widget.roomModel.anchorId ?? roomInfoObject!.anchorId!) ??
        widget.roomModel.okNickName;
  }

  Future getAudience() async {
    if (widget.roomModel.audienceCount == null) {
      final Map status = await Api.liveStatistics(widget.roomModel.roomId!);
      if (status["code"] == 200) {
        final CloseRoomModel closeAudienceRoom =
            CloseRoomModel.fromJson(status["data"]);
        widget.roomModel.audienceCount = closeAudienceRoom.audience;
        // ignore: invalid_use_of_protected_member
        topKey.currentState?.setState(() {});
      } else {
        myFailToast('????????????');
      }
    }
  }

  /*
  * ??????????????????
  * */
  Future getRoomInfo() async {
    final Map resultData = await Api.getRoomInfo(widget.roomModel.roomId!);
    if (resultData["code"] == 200) {
      roomInfoObject = RoomInfon.fromJson(resultData["data"]);

      serverId = roomInfoObject!.serverId;

      /// ?????????????????????????????????????????????
      await playbackEnter();

      /// ??????????????????
      PlaybackLogUp.playBackEnter(
        statePage.widget.isFromList,
        widget.roomModel.roomId,
        widget.roomModel.serverId ?? roomInfoObject?.serverId,
        widget.roomModel.channelId ?? roomInfoObject?.channelId,
      );
    }
  }

  /*
  * ??????????????????????????????Api???
  * */
  Future playbackEnter() async {
    await Api.playbackEnter(fbApi.getUserId(), roomInfoObject!.roomId);
  }

  /*
  * ??????????????????????????????Api???
  * */
  Future playbackExit() async {
    final String? joinDurationStr = fbApi.getSharePref("join_duration");
    int? joinDuration;
    if (strNoEmpty(joinDurationStr)) {
      final int mel = int.parse(joinDurationStr!);
      final int nowMel = DateTime.now().millisecondsSinceEpoch;
      joinDuration = (nowMel - mel) ~/ 1000;
    }

    await Api.playbackExit(
        fbApi.getUserId(), roomInfoObject!.roomId, joinDuration);
  }

  /*
  * ??????
  * */
  Future onRefreshMsg() async {
    data.clear();
    data = await fbApi.getLiveHistoryMessages(
        fbApi.getUserId()!, widget.roomModel.roomId!);
    await updateNames(data);
    if (listNoEmpty(data)) {
      chatListBlocModel.add(data[0]);
    }
  }

  /*
  * ????????????
  * */
  Future<void> getData() async {
    if (listNoEmpty(data)) {
      final dataList = await fbApi.getLiveHistoryMessages(
          fbApi.getUserId()!, widget.roomModel.roomId!,
          lastMessageId: data[data.length - 1]["message_id"]);
      await updateNames(dataList);
      if (listNoEmpty(dataList)) {
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
      data.addAll(dataList);
    } else {
      data = await fbApi.getLiveHistoryMessages(
          fbApi.getUserId()!, widget.roomModel.roomId!);
      await updateNames(data);
      refreshController.loadComplete();
    }
    onRefresh();
  }

  /*
  * ??????????????????
  * */
  Future<void> updateNames(List<Map<String, dynamic>> messageList) async {
    final List<String> userIds = [];
    for (int i = 0; i < messageList.length; i++) {
      userIds.add(messageList[i]['user_id']);
    }

    final Map<String?, String> names = await fbApi.getShowNames(
      userIds,
      guildId: serverId!,
    );

    for (int i = 0; i < messageList.length; i++) {
      final userId = messageList[i]['user_id'];
      final author = messageList[i]['author'];
      if (strNoEmpty(names[userId]) && author != null) {
        author['nickname'] = names[userId];
      }
    }
  }

  /*
  * ??????????????????
  * */
  Future playbackWatch() async {
    await Api.playbackWatch(widget.roomModel.roomId);
  }

  @override
  Future<void> close() {
    _roomBottomBlocModel?.close();
    _screenClearBlocModel?.close();
    _emojiKeyBoardBlocModel?.close();

    closeLBus?.cancel();
    closeLBus = null;

    /// ????????????????????????
    playbackExit();

    /// ??????????????????
    PlaybackLogUp.liveLeave(
      widget.roomModel.roomId,
      widget.roomModel.serverId ?? roomInfoObject?.serverId,
      widget.roomModel.channelId ?? roomInfoObject?.channelId,
    );
    // ????????????????????????????????????
    WindowUtil.setStatusTextColorBlack();

    if (isSetWakelock) {
      /// ??????????????????
      Wakelock.disable();
    }

    return super.close();
  }
}
