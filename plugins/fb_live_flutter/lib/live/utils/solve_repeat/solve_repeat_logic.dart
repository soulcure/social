import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/bloc/logic/live_load_logic.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc_model/anchor_close_live_bt_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/chat_list_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/emoji_keyborad_block_model.dart';
import 'package:fb_live_flutter/live/bloc_model/fb_base_bloc.dart';
import 'package:fb_live_flutter/live/bloc_model/fb_refresh_widget_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/gift_click_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/gift_move_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/like_click_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/live_preview_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/online_user_count_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/room_bottom_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/screen_clear_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/sheet_gifts_bottom_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/shop_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/tips_login_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/user_join_live_room_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/emoji_keyboard_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/liveroom_chat_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/sheet_gifts_bottom_model.dart';
import 'package:fb_live_flutter/live/model/colse_room_model.dart';
import 'package:fb_live_flutter/live/model/live/view_render_alg_model.dart';
import 'package:fb_live_flutter/live/model/online_user_count.dart';
import 'package:fb_live_flutter/live/model/room_giftsendsuc_model.dart';
import 'package:fb_live_flutter/live/model/zego_token_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/close_room/close_room_anchor.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/up_click_widget.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: implementation_imports
import 'package:flutter_bloc/src/bloc_provider.dart' as bloc_p;
import 'package:zego_express_engine/zego_express_engine.dart';

abstract class LiveLogicCommonAbs {
  bool? get isOverlayViewPushValue;

  String? get widgetRoomId;

  bool? get widgetIsAnchor;

  bool? get widgetIsFromList;

  bool get anchorIsObs;

  Future<void> anchorCloseRoom();

  Future setLiveObsStart();
}

mixin LiveLogicCommon
    on GoodsLogic, LiveInterface, LiveLogicCommonAbs, LiveLoadLogic, LiveMix
    implements FBLiveMsgHandler {
  /// ????????????--start
  LikeClickBlocModel? likeClickBlocModel;
  ChatListBlocModel? chatListBlocModel;
  GiftClickBlocModel? giftClickBlocModel;

  /// ????????????3???????????????
  GiftMoveBlocModel? giftMoveBlocModel;
  GiftMoveBlocModel2? giftMoveBlocModel2;
  GiftMoveBlocModel3? giftMoveBlocModel3;
  LivePreviewBlocModel? livePreviewBlocModel;
  ScreenClearBlocModel? screenClearBlocModel;
  LikeClickPreviewBlocModel? likeClickPreviewBlocModel;
  late UserJoinLiveRoomModel userJoinLiveRoomModel;
  OnlineUserCountBlocModel? onlineUserCountBlocModel;
  AnchorCloseLiveBtBlocModel? anchorCloseLiveBtBlocModel;
  RoomBottomBlocModel? roomBottomBlocModel;
  late SheetGiftsBottomBlocModel sheetGiftsBottomBlocModel;
  late EmojiKeyBoradBlocModel emojiKeyBoardBlocModel;
  TipsLoginBlocModel? tipsLoginBlocModel;

  /// ????????????--end

  /// ????????????EvenBus--start
  StreamSubscription? sendGiftsEventBusValue;
  StreamSubscription? goodsHtmlBusValue;
  StreamSubscription? goodsHtmlIosBusValue;
  StreamSubscription? subscriptionValue;
  StreamSubscription? emojiSubscriptionValue;

  /// ????????????EvenBus--end

  bool isPlaying = true; //?????????????????????

  List<AnimationController> animationControllerList = [];
  List<Widget> upLickWidgetList = [];

  List onlineUser = []; //??????????????????
  OnlineUserCount? onlineUserCountModel; //??????????????????
  List? userOnlineList; //????????????????????????

  Timer? liveTimer;

  final Queue<FBUserInfo> userJoinQueue = Queue<FBUserInfo>();
  final Queue<GiveGiftModel> giftQueue = Queue<GiveGiftModel>();
  final List<GiveGiftModel> mySelfGiftsList = []; //???????????????????????????
  FBUserInfo? joinedUserInfo;

  GiveGiftModel? giveGiftModel1, giveGiftModel2, giveGiftModel3;
  bool isClickUp = false; //???????????????

  StreamController<List<Widget>> widgetListStreamController =
      StreamController();

  /// ??????app?????????????????????/??????app/??????????????????????????????
  /// android??????????????????
  bool isOutsideApp = false;

  List<bloc_p.BlocProviderSingleChildWidget> get providers {
    return [
      BlocProvider<ChatListBlocModel>(
        create: (context) {
          return chatListBlocModel = ChatListBlocModel(null);
        },
      ),
      BlocProvider<LikeClickBlocModel>(
        create: (context) {
          return likeClickBlocModel = LikeClickBlocModel(0);
        },
      ),
      BlocProvider<GiftClickBlocModel>(
        create: (context) {
          return giftClickBlocModel = GiftClickBlocModel(0);
        },
      ),
      BlocProvider<GiftMoveBlocModel>(
        create: (context) {
          return giftMoveBlocModel = GiftMoveBlocModel(null);
        },
      ),
      BlocProvider<GiftMoveBlocModel2>(
        create: (context) {
          return giftMoveBlocModel2 = GiftMoveBlocModel2(null);
        },
      ),
      BlocProvider<GiftMoveBlocModel3>(
        create: (context) {
          return giftMoveBlocModel3 = GiftMoveBlocModel3(null);
        },
      ),
      BlocProvider<LivePreviewBlocModel>(
        create: (context) {
          return livePreviewBlocModel =
              LivePreviewBlocModel(liveValueModel!.textureId);
        },
      ),
      BlocProvider<ScreenClearBlocModel>(
        create: (context) {
          return screenClearBlocModel = ScreenClearBlocModel(false);
        },
      ),
      BlocProvider<LikeClickPreviewBlocModel>(
        create: (context) {
          return likeClickPreviewBlocModel = LikeClickPreviewBlocModel(0);
        },
      ),
      BlocProvider<UserJoinLiveRoomModel>(
        create: (context) {
          return userJoinLiveRoomModel = UserJoinLiveRoomModel(null);
        },
      ),
      BlocProvider<PushGoodsLiveRoomModel>(
        create: (context) {
          /// ????????????????????????????????????????????????????????????FBUserInfo
          return pushGoodsLiveRoomModel = PushGoodsLiveRoomModel(null);
        },
      ),
      BlocProvider<OnlineUserCountBlocModel>(
        create: (context) {
          return onlineUserCountBlocModel = OnlineUserCountBlocModel(0);
        },
      ),
      BlocProvider<AnchorCloseLiveBtBlocModel>(
        create: (context) {
          return anchorCloseLiveBtBlocModel = AnchorCloseLiveBtBlocModel(0);
        },
      ),
      BlocProvider<RoomBottomBlocModel>(
        create: (context) {
          return roomBottomBlocModel = RoomBottomBlocModel(RefreshState.none);
        },
      ),
      BlocProvider<SheetGiftsBottomBlocModel>(create: (context) {
        return sheetGiftsBottomBlocModel = SheetGiftsBottomBlocModel(0);
      }),
      BlocProvider<EmojiKeyBoradBlocModel>(create: (context) {
        return emojiKeyBoardBlocModel = EmojiKeyBoradBlocModel(0);
      }),
      BlocProvider<ShopBlocModelQuick>(
        create: (context) => shopBlocModelQuick = ShopBlocModelQuick(null),
      ),
      BlocProvider<CouponsBlocModelQuick>(
        create: (context) =>
            couponsBlocModelQuick = CouponsBlocModelQuick(null),
      ),
      BlocProvider<TipsLoginBlocModel>(
        create: (context) => tipsLoginBlocModel = TipsLoginBlocModel(null),
      ),
    ];
  }

  void okContext(BuildContext ctx) {
    context = ctx;
    return;
  }

  ViewRenderAlgModel viewRenderAlg() {
    final ViewRenderAlgModel model = ViewRenderAlgModel();

    /// ????????????????????????????????????????????????????????????????????????????????????????????????isScreenRotation??????
    final double screenWidth =
        !isScreenRotation ? FrameSize.screenW() : FrameSize.screenH();
    final double screenHeight =
        !isScreenRotation ? FrameSize.screenH() : FrameSize.screenW();

    // 1. ??????????????????
    if (!isScreenRotation) {
      if (liveValueModel!.playerVideoWidth >
              liveValueModel!.playerVideoHeight ||
          liveValueModel!.screenDirection != "V") {
        model.viewMode = ZegoViewMode.AspectFit;
        model.axis = Axis.horizontal;

        if (liveValueModel!.playerVideoWidth >
            liveValueModel!.playerVideoHeight) {
          model.viewWidth = screenWidth;
          model.viewHeight = model.viewWidth *
              liveValueModel!.playerVideoHeight /
              liveValueModel!.playerVideoWidth;
        } else {
          model.viewWidth = screenWidth *
              liveValueModel!.playerVideoWidth /
              liveValueModel!.playerVideoHeight;
          model.viewHeight = screenWidth;
          model.needRotate = true;
        }
      }

      if (liveValueModel!.playerVideoWidth <
              liveValueModel!.playerVideoHeight &&
          liveValueModel!.screenDirection == "V") {
        model.viewMode = liveValueModel!.isScreenPush
            ? ZegoViewMode.AspectFit
            : ZegoViewMode.AspectFill;
        model.axis = Axis.vertical;
        model.viewWidth = screenWidth;
        model.viewHeight = screenHeight;
      }
      return model;
    }
    // 2. ??????????????????
    if (liveValueModel!.playerVideoWidth > liveValueModel!.playerVideoHeight ||
        liveValueModel!.screenDirection != "V") {
      model.viewMode = ZegoViewMode.AspectFit;
      model.axis = Axis.horizontal;
      if (liveValueModel!.playerVideoWidth >
          liveValueModel!.playerVideoHeight) {
        model.viewWidth = screenWidth;
        model.viewHeight = screenHeight;
      } else {
        model.viewWidth = screenHeight;
        model.viewHeight = screenWidth;
        model.needRotate = true;
      }
    }
    if (liveValueModel!.playerVideoWidth < liveValueModel!.playerVideoHeight &&
        liveValueModel!.screenDirection == "V") {
      model.viewMode = ZegoViewMode.AspectFit;
      model.axis = Axis.vertical;
      model.viewWidth = screenWidth;
      model.viewHeight = screenHeight;
    }
    return model;
  }

  void upLikeClickBlock(
      int likeNum, String typeString, TickerProvider tickerProvider) {
    if (typeString == 'animation') {
      final AnimationController controller = AnimationController(
          duration: const Duration(milliseconds: 1000), vsync: tickerProvider);

      controller.forward().orCancel;
      upLickWidgetList.add(UpClickAnimation(
        randomNum: Random().nextInt(6),
        controller: controller,
      ));
      animationControllerList.add(controller);
      widgetListStreamController.sink.add(upLickWidgetList);
    } else {
      var _thumbCount = onlineUserCountModel!.thumbCount;
      if (_thumbCount != null) {
        _thumbCount += likeNum;
        onlineUserCountModel!.thumbCount = _thumbCount;
      }

      // ??????
      likeClickPreviewBlocModel!.add(onlineUserCountModel!.thumbCount);
      if (isClickUp == false) {
        fbApiSendLiveMsg("??????????????????");
        isClickUp = true;
      }
    }
  }

  void sendGiftsClickBlock(GiftSuccessModel model) {
    final Map<String, dynamic> giftInfo = {
      'giftId': model.giftId,
      'giftName': model.giftName,
      'giftQt': model.giftQt,
      'giftImgUrl': model.giftImgUrl,
      'type': "gifts"
    };

    //??????????????????
    final String? userId = fbApi.getUserId();
    fbApi
        .getUserInfo(userId!, guildId: getRoomInfoObject!.serverId)
        .then((user) {
      final GiveGiftModel giveGiftModel =
          GiveGiftModel(sendUserInfo: user, giftInfo: giftInfo);
      mySelfGiftsList.add(giveGiftModel);
      checkGiftMoveMsg(giveGiftModel, isMySelfGift: true);
      final Map chatMap = {
        "user": user,
        "text": giftInfo,
        "type": "give_gifts"
      };
      liveValueModel!.chatList.add(chatMap);
      chatListBlocModel!.add(chatMap);
    });
  }

  /*
  * ???????????????????????????
  * */
  void checkGiftMoveMsg(GiveGiftModel? giveGiftModel,
      {bool next = false, bool isMySelfGift = false}) {
    if (giveGiftModel != null) {
      if (isMySelfGift) {
        giftQueue.addFirst(giveGiftModel);
      } else {
        giftQueue.addLast(giveGiftModel);
      }
    }

    playGiftAnimate(giveGiftModel1, giftMoveBlocModel);
    playGiftAnimate(giveGiftModel2, giftMoveBlocModel2);
    playGiftAnimate(giveGiftModel3, giftMoveBlocModel3);
  }

  /*
  * ??????????????????-??????????????????
  * */
  void playGiftAnimate(GiveGiftModel? giftModel, FBBaseBlocModel? blocModel) {
    if (giftModel == null) {
      if (giftQueue.isNotEmpty) {
        giftModel = giftQueue.removeFirst();
        giftModel.count = 1;

        /// ???APP???????????????????????????????????????x1????????????????????????????????????????????????????????????
        /// ????????????????????????????????????
        blocModel!.add(null);
        Future.delayed(const Duration(milliseconds: 30), () {
          blocModel.add(giftModel);
        });
      }
    }
  }

  // FBAPI--??????????????????
  void fbApiStopLive() {
    fbApi.stopLive(getRoomInfoObject!.serverId, getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel!.roomId!);
  }

  // ???????????????????????????????????????
  Future<void> audienceCloseRoom() async {
    isShowOverlayView = false;

    // ????????????
    goBack();
    EventBusManager.eventBus.fire(RefreshRoomListModel(true));
  }

  /*
  * ??????????????????
  *
  * ?????????x?????????????????????[goBack]??????[didPop]???????????????????????????????????????????????????
  * */
  Future exitReport() async {
    /// ??????????????????[exitReport-??????????????????]???????????????????????????
    if (isAnchor) {
      /// ???????????????????????????????????????
      /// ??????[anchorCloseRoom]??????"????????????"???"??????IM????????????"???
      return;
    }

    // ????????????
    await setLiveExit();
    // FB ??????????????????
    fbApiExitLiveRoom();
    // ??????IM????????????
    fbApiRemoveLiveMsgHandler();
  }

  //2???????????????
  void fbApiRegisterMsgHandler() {
    fbApi.registerLiveMsgHandler(this);
  }

  //3???????????????
  void fbApiRemoveLiveMsgHandler() {
    fbApi.removeLiveMsgHandler(this);
  }

  // ?????????????????????????????????
  Future setLiveExit() async {
    await Api.liveExit(widgetRoomId, liveValueModel!.zegoTokenModel?.userToken,
        widgetIsAnchor!, getRoomInfoObject!);
  }

  // FBAPI--??????????????????
  Future fbApiEnterLiveRoom() async {
    if (isOverlayViewPushValue != null && isOverlayViewPushValue!) {
      /// ???????????????????????????????????????????????????2021 10.27???
      return;
    }
    await fbApi.enterLiveRoom(
        getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel?.roomId ?? widgetRoomId!,
        isAnchor,
        getRoomInfoObject!.serverId,
        isOverlayViewPush ?? false);
  }

  // FBAPI--??????????????????
  void fbApiExitLiveRoom() {
    fbApi.exitLiveRoom(
        getRoomInfoObject!.serverId,
        getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel?.roomId ?? widgetRoomId!);
  }

  // FBAPI--??????????????????
  void fbApiSendLiveMsg(String content) {
    LiveLogUp.send(content, getRoomInfoObject!);
    fbApi.inspectChatMsg(content).then((value) {
      if (value) {
        final String json = _formatMsgJSON(content);
        fbApi.sendLiveMsg(
            getRoomInfoObject!.serverId,
            getRoomInfoObject!.channelId,
            liveValueModel!.zegoTokenModel!.roomId!,
            json);
      }
    });
  }

  // FBAPI--??????????????????
  static String _formatMsgJSON(String content) {
    final Map msgJSON = {};
    msgJSON['content'] = content;
    return json.encode(msgJSON);
  }

  //??????????????????
  Future getOnLineCount() async {
    /// ?????????????????????????????????????????????
    /// ???2021 11.23???2. ?????????????????????????????????????????????????????????????????????
    if (!isShowOverlayView || routeHasLive) {
      final Map onlineData =
          await Api.getOnlineCount(widgetRoomId!, getRoomInfoObject!);
      if (onlineData["code"] == 200) {
        onlineUserCountModel = OnlineUserCount.fromJson(onlineData["data"]);
        onlineUserCountBlocModel!.add(onlineUserCountModel!.total);
        likeClickPreviewBlocModel?.add(onlineUserCountModel!.thumbCount);
      }
    }
  }

  // ??????????????????
  Future anchorCloseLive() async {
    isProactiveClose = true;
    final Map status = await Api.closeLiveRoom(widgetRoomId!);
    if (status["code"] == 200) {
      if (!fanBookClose) {
        final CloseRoomModel closeRoomModel =
            CloseRoomModel.fromJson(status["data"]);

        _navigatorToAnchorClosePage(closeRoomModel);
      }
    } else {
      /// ???2022 01.25???????????????????????????
      await closeFail();
    }
  }

  // ??????????????????-????????????
  void _navigatorToAnchorClosePage(CloseRoomModel closeRoomModel) {
    RouteUtil.popToLive();

    fbApi
        .push(
            context!,
            CloseRoom(
              closeRoomModel: closeRoomModel,
              roomInfoObject: getRoomInfoObject,
              liveValueModel: liveValueModel,
            ),
            "liveCloseRoom",
            isReplace: mounted)
        .then((value) {
      EventBusManager.eventBus.fire(RefreshRoomListModel(true));
    });
  }

  @override
  void onLiveStop() {
    // TODO: implement onLiveStop
  }

  /// ??????????????????
  @override
  void onGoodsNotice(FBUserInfo user, String type, String json) {
    onGoodsNoticeHandle(user, type, json, widgetIsAnchor, widgetRoomId);
  }

  /// ????????????????????????
  /// @param user: ???????????????????????????
  /// @param json: ???????????????????????????????????????
  @override
  void onReceiveChatMsg(FBUserInfo user, String json) {
    final Map textMap = jsonDecode(json);
    final String? text = textMap["content"];
    final Map chatMap = {"user": user, "text": text, "type": "user_chat"};
    liveValueModel!.chatList.add(chatMap);
    chartEventBus.fire(LiveRoomChartEvent(liveValueModel!.chatList));

    /// ?????????????????????????????????
    if (!chatListBlocModel!.isClosed) {
      chatListBlocModel?.add(chatMap);
    }
  }

  /// ??????????????????
  /// @param user: ??????????????????
  /// @param json: ???????????????????????????????????????
  @override
  void onSendGift(FBUserInfo user, String jsonMsg) {
    getOnLineCount();
    final String? _userId = fbApi.getUserId();
    if (user.userId != _userId) {
      final Map<String, dynamic>? giftInfo = json.decode(jsonMsg);
      final GiveGiftModel giveGiftModel =
          GiveGiftModel(sendUserInfo: user, giftInfo: giftInfo);
      checkGiftMoveMsg(giveGiftModel);
      final Map chatMap = {
        "user": user,
        "text": giftInfo,
        "type": "give_gifts"
      };
      liveValueModel!.chatList.add(chatMap);
      chatListBlocModel!.add(chatMap);
      chartEventBus.fire(LiveRoomChartEvent(liveValueModel!.chatList));
    }
  }

  /// ?????????????????????
  /// @param user: ????????????????????????
  @override
  void onUserEnter(FBUserInfo user) {
    if (user.userId != getRoomInfoObject!.anchorId) {
      //?????????????????????
      final Map chatMap = {"user": user, "text": "??????", "type": "user_coming"};
      liveValueModel!.chatList.add(chatMap);
      chartEventBus.fire(LiveRoomChartEvent(liveValueModel!.chatList));
      chatListBlocModel!.add(chatMap);

      var _total = onlineUserCountModel?.total;
      if (_total != null) {
        ++_total;
        onlineUserCountModel?.total = _total;
      }

      onlineUserCountBlocModel!.add(_total);
      userJoinQueue.addLast(user);
      if (joinedUserInfo == null) {
        joinedUserInfo = userJoinQueue.removeFirst();
        userJoinLiveRoomModel.add(joinedUserInfo);
      }
    }

    if (onlineUserCountModel?.total != null &&
        (onlineUserCountModel?.total ?? 0) < 3) {
      getOnLineCount();
    }
  }

  /// ?????????????????????
  /// @param user: ????????????????????????
  @override
  void onUserQuit(FBUserInfo user) {
    var _total = onlineUserCountModel?.total;
    if (_total != null) {
      --_total;
      onlineUserCountModel?.total = _total;
    }

    onlineUserCountBlocModel!.add(onlineUserCountModel?.total);
    if (onlineUserCountModel?.total != null &&
        (onlineUserCountModel?.total ?? 0) < 3) {
      getOnLineCount();
    } else {
      /// ???????????????????????????????????????null
      onlineUserCountModel?.users?.forEach((element) {
        if (element.userId == user.userId) {
          getOnLineCount();
        }
      });
    }
  }

  // ???????????????
  @override
  void onKickOutOfGuild() {
    if (!isAnchor) {
      return;
    }
    liveValueModel!.liveStatus = LiveStatus.kickOutServer;
    eventBus.fire(LiveStatusEvent(LiveStatus.kickOutServer));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        myToastLong('????????????????????????????????????????????????????????????????????????',
            duration: const Duration(days: 1)); // ???????????????
      });
      // ??????3S,???????????????
      Future.delayed(const Duration(seconds: 3), anchorCloseRoom);
    }
  }

  // ??????????????????
  Future anchorStartLive() async {
    final Map status = await Api.starteLive(widgetRoomId!);
    if (status['code'] == 200) {
      liveValueModel!.liveStatus = LiveStatus.openLiveSuccess;
      eventBus.fire(LiveStatusEvent(LiveStatus.openLiveSuccess));

      /// ????????????????????????????????????setState
      isStartLive = false;
      roomBottomBlocModel!.add(true);
      // ???????????????
      await setLiveEnter();
      if (anchorIsObs) {
        // ???????????????obs????????????
        await setLiveObsStart();
      }
      // ??????FB
      await fbApiEnterLiveRoom();

      // ??????????????????
      await goodsApi(widgetRoomId!, this);

      if (anchorIsObs) {
        // ???APP???????????????IOS???OBS??????????????????????????????????????????????????????????????????????????????????????????
        livePreviewBlocModel!.add(0);
      }
    } else {
      liveValueModel!.liveStatus = LiveStatus.openLiveFailed;
      eventBus.fire(LiveStatusEvent(LiveStatus.openLiveFailed));
      if (!isShowOverlayView || routeHasLive) {
        showConfirmDialog(() {
          Loading.showConfirmDialog(
              context!,
              // TODO ?????? obs??????????????????????????????????????????
              (liveValueModel?.getIsObs ?? false)
                  ? {
                      'content': '????????????????????????????????????',
                      'cancelText': '??????',
                      'confirmText': '??????'
                    }
                  : {
                      'content': '???????????????????????????',
                      'cancelText': '??????',
                      'confirmText': '??????'
                    },
              anchorStartLive, cancelCallback: () {
            goBack();
          });
        });
      }
    }
  }

  // ?????????????????????????????????
  Future setLiveEnter() async {
    final liveEnter = await Api.liveEnter(
        widgetRoomId, liveValueModel!.zegoTokenModel?.userToken);
    if (liveEnter != "" && liveEnter != null) {
      if (liveEnter['code'] == null || liveEnter['code'] == 400) {
        showConfirmDialog(() {
          Loading.showConfirmDialog(
              context!,
              {
                'content': '??????????????????????????????',
                'cancelText': '??????',
                'confirmText': '??????',
                'cancelShow': false
              },
              anchorStartLive, cancelCallback: () {
            goBack();
          });
        });
      }
    }

    // ???????????????????????????
    if (!widgetIsAnchor! && !isOverlayViewPush! && widgetIsFromList != null) {
      LiveLogUp.liveEnter(widgetIsFromList!, widgetRoomId!,
          getRoomInfoObject!.serverId, getRoomInfoObject!.channelId);
    }

    await getOnLineCount(); //?????????????????????????????????
  }

  //??????
  Future<void> getZegoToken() async {
    final Map resultData = await Api.getZegoToken(widgetRoomId!);

    if (resultData["code"] == 200) {
      liveValueModel!.zegoTokenModel =
          ZegoTokenModel.fromJson(resultData["data"]);
      //???????????????SDK
      if (liveValueModel!.zegoTokenModel!.userId ==
          liveValueModel!.zegoTokenModel!.anchorId) {
        //???????????????ID??????  ??????????????????
        isAnchor = true;
      } else {
        isAnchor = false;
      }

      await fbApi.setSharePref(
          "live_userToken", liveValueModel!.zegoTokenModel!.userToken!);
    }
  }

  /*
  * ??????????????????
  * */
  Future getCurrentUser() async {
    try {
      // ????????????????????????
      await getZegoToken();

      // emoji
      subscriptionValue =
          EventBusManager.eventBus.on<SheetGiftsBottomModel>().listen((event) {
        final double? ph = event.height;
        sheetGiftsBottomBlocModel.add(ph);
      });

      emojiSubscriptionValue =
          EventBusManager.eventBus.on<EmojiKeyBoardModel>().listen((event) {
        final double? ph = event.height;
        emojiKeyBoardBlocModel.add(ph);
      });
    } catch (e) {
      Future.delayed(Duration.zero, () {
        Loading.showConfirmDialog(
            context!,
            {
              'content': '???????????????????????????????????????????????????????????????????????????',
              'confirmText': '??????',
              'cancelShow': false
            },
            goBack);
      });
    }
  }

  Future<bool> fanBookCloseListener() async {
    fanBookClose = true;
    if (isAnchor) {
      await anchorCloseRoom();
    } else {
      await audienceCloseRoom();
    }
    return true;
  }

  void animationCompleteGiftsThree(_) {
    giveGiftModel3 = null;
    giftMoveBlocModel3!.add(null);
    checkGiftMoveMsg(null, next: true);
  }

  void animationCompleteGiftsTwo(_) {
    giveGiftModel2 = null;
    giftMoveBlocModel2!.add(null);
    checkGiftMoveMsg(null, next: true);
  }

  void animationCompleteGiftsOne(_) {
    giveGiftModel1 = null;
    giftMoveBlocModel!.add(null);
    checkGiftMoveMsg(null, next: true, isMySelfGift: true);
  }

  /*
  * ?????????????????????????????????
  * */
  void cleanGiftBloc() {
    if (giftMoveBlocModel != null) {
      giveGiftModel1 = null;
      giftMoveBlocModel!.add(null);
    }

    if (giftMoveBlocModel2 != null) {
      giveGiftModel2 = null;
      giftMoveBlocModel2!.add(null);
    }

    if (giftMoveBlocModel3 != null) {
      giveGiftModel3 = null;
      giftMoveBlocModel3!.add(null);
    }
  }

  void animationCompeteTips() {
    if (userJoinQueue.isNotEmpty) {
      joinedUserInfo = userJoinQueue.removeFirst();
    } else {
      joinedUserInfo = null;
    }
    userJoinLiveRoomModel.add(joinedUserInfo);
  }

  // ????????????????????????
  void startTimerGetOnline() {
    cancelTimer();
    liveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getOnLineCount();
    });
  }

  /*
  * ????????????????????????
  * */
  void liveRoomInfoFail() {
    const String roomInfoFailStir = "??????????????????????????????";

    myFailToast(roomInfoFailStir);
    fbApi.fbLogger.info(roomInfoFailStir);

    // ?????????????????????????????????
    livePreviewBlocModel!.add(0);
  }

  // ???????????????
  void cancelTimer() {
    liveTimer?.cancel();
  }

  /*
  * ????????????????????????
  * */
  void cancelSubAndStream() {
    widgetListStreamController.close();

    sendGiftsEventBusValue?.cancel();
    goodsHtmlBusValue?.cancel();
    goodsHtmlIosBusValue?.cancel();

    subscriptionValue?.cancel();
    subscriptionValue = null;
    emojiSubscriptionValue?.cancel();
    emojiSubscriptionValue = null;
  }
}

/*
* ??????????????????
* */
mixin LiveStatusHandle
    on LiveMix, LiveLoadLogic, LiveInterface, LiveLogicCommon {
  void netErrorStatusHandle() {
    Future.delayed(Duration.zero, () {
      Loading.showConfirmDialog(
          context!,
          {
            'content': '???????????????????????????????????????????????????????????????????????????',
            'confirmText': '??????',
            'cancelShow': false
          },
          goBack);
    });
  }

  void cantOpenLiveStatusHandle() {
    liveValueModel!.liveStatus = LiveStatus.networkError;
    eventBus.fire(LiveStatusEvent(LiveStatus.networkError));
    showConfirmDialog(() {
      Loading.showConfirmDialog(
          context!,
          {
            'content': '??????????????????????????????????????????????????????',
            'confirmText': '??????',
            'cancelShow': false
          },
          goBack);
    });
  }

  void netWordErrorStatusHandle() {
    liveValueModel!.liveStatus = LiveStatus.networkError;
    eventBus.fire(LiveStatusEvent(LiveStatus.networkError));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialogNew();
    } // ???????????????????????????????????????????????????
  }

  void netConfigStatusHandle() {
    liveValueModel!.liveStatus = LiveStatus.networkError;
    eventBus.fire(LiveStatusEvent(LiveStatus.networkError));
    if (!isShowOverlayView || routeHasLive) {
      myFailToast('????????????????????????????????????', duration: const Duration(days: 1));
    } // ???????????????????????????????????????????????????
  }

  void abnormalLoginStatusHandle() {
    // 1002050	????????????????????????????????????????????? ID ?????????????????????
    liveValueModel!.liveStatus = LiveStatus.abnormalLogin;
    eventBus.fire(LiveStatusEvent(LiveStatus.abnormalLogin));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        RouteUtil.popToLive();
        Loading.showConfirmDialog(context!, {
          'content': '?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????',
          'confirmText': '??????',
          'cancelShow': false
        }, () {
          goBack();
          EventBusManager.eventBus.fire(RefreshRoomListModel(true));
        });
      });
    }
  }

  void playFailStatusHandle() {
    liveValueModel!.liveStatus = LiveStatus.playStreamFailed;
    eventBus.fire(LiveStatusEvent(LiveStatus.playStreamFailed));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        Loading.showConfirmDialog(
            context!,
            {'content': '???????????????????????????', 'confirmText': '??????', 'cancelShow': false},
            setStreamAndTexture);
      });
    }
  }

  void offlineStatusHandle() {
    showConfirmDialog(() {
      Loading.showConfirmDialog(
          context!,
          {
            'content': '??????????????????????????????????????????',
            'confirmText': '??????',
            'cancelShow': false
          },
          goBack);
    });
  }

  Future violationsStatusHandle() async {
    await FbApiModel.violationsAction(getRoomInfoObject!.roomId);
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        Loading.showConfirmDialog(
            context!,
            {
              'content': '?????????????????????????????????????????????????????????????????????????????????????????????',
              'confirmText': '??????',
              'cancelShow': false
            },
            goBack);
      });
    }
  }

  void timeoutStatusHandle() {
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        Loading.showConfirmDialog(
            context!,
            {'content': '???????????????????????????', 'confirmText': '??????', 'cancelShow': false},
            goBack);
      });
    }
  }

  Future systemBanStatusHandle() async {
    await FbApiModel.violationsAction(getRoomInfoObject!.roomId);
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        Loading.showConfirmDialog(
            context!,
            {
              'content': '??????????????????????????????????????????????????????????????????????????????????????????',
              'confirmText': '??????',
              'cancelShow': false
            },
            goBack);
      });
    }
  }
}
