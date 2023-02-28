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
  /// 状态管理--start
  LikeClickBlocModel? likeClickBlocModel;
  ChatListBlocModel? chatListBlocModel;
  GiftClickBlocModel? giftClickBlocModel;

  /// 从上到下3个礼物位置
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

  /// 状态管理--end

  /// 事件总线EvenBus--start
  StreamSubscription? sendGiftsEventBusValue;
  StreamSubscription? goodsHtmlBusValue;
  StreamSubscription? goodsHtmlIosBusValue;
  StreamSubscription? subscriptionValue;
  StreamSubscription? emojiSubscriptionValue;

  /// 事件总线EvenBus--end

  bool isPlaying = true; //第一次拉流上报

  List<AnimationController> animationControllerList = [];
  List<Widget> upLickWidgetList = [];

  List onlineUser = []; //在线用户列表
  OnlineUserCount? onlineUserCountModel; //在线人数数量
  List? userOnlineList; //在线用户详情列表

  Timer? liveTimer;

  final Queue<FBUserInfo> userJoinQueue = Queue<FBUserInfo>();
  final Queue<GiveGiftModel> giftQueue = Queue<GiveGiftModel>();
  final List<GiveGiftModel> mySelfGiftsList = []; //显示自己打赏的礼物
  FBUserInfo? joinedUserInfo;

  GiveGiftModel? giveGiftModel1, giveGiftModel2, giveGiftModel3;
  bool isClickUp = false; //是否点过赞

  StreamController<List<Widget>> widgetListStreamController =
      StreamController();

  /// 是否app外面【退到桌面/其他app/正在运行的应用列表】
  /// android悬浮窗用到。
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
          /// 如果要提示自己加入房间，则传入自己信息的FBUserInfo
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

    /// 因为防止旋转中途去刷新视图，获取的屏幕宽高不准确，使用竖屏数据，isScreenRotation区分
    final double screenWidth =
        !isScreenRotation ? FrameSize.screenW() : FrameSize.screenH();
    final double screenHeight =
        !isScreenRotation ? FrameSize.screenH() : FrameSize.screenW();

    // 1. 观众手机竖屏
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
    // 2. 观众手机横屏
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

      // 点赞
      likeClickPreviewBlocModel!.add(onlineUserCountModel!.thumbCount);
      if (isClickUp == false) {
        fbApiSendLiveMsg("为主播点赞了");
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

    //发送礼物消息
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
  * 添加礼物队列及处理
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
  * 处理动画事件-发送礼物动画
  * */
  void playGiftAnimate(GiveGiftModel? giftModel, FBBaseBlocModel? blocModel) {
    if (giftModel == null) {
      if (giftQueue.isNotEmpty) {
        giftModel = giftQueue.removeFirst();
        giftModel.count = 1;

        /// 【APP】观众礼物送出时，后面数字x1，有跳动，礼物的动画就一直卡在那里没消失
        /// 先清除这个位置之前的动画
        blocModel!.add(null);
        Future.delayed(const Duration(milliseconds: 30), () {
          blocModel.add(giftModel);
        });
      }
    }
  }

  // FBAPI--主播停止直播
  void fbApiStopLive() {
    fbApi.stopLive(getRoomInfoObject!.serverId, getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel!.roomId!);
  }

  // 观众关闭直播页面，退出房间
  Future<void> audienceCloseRoom() async {
    isShowOverlayView = false;

    // 手势返回
    goBack();
    EventBusManager.eventBus.fire(RefreshRoomListModel(true));
  }

  /*
  * 直播退出上报
  *
  * 手动点x不需要调用此，[goBack]时到[didPop]会不满足显示悬浮窗资格然后调用到此
  * */
  Future exitReport() async {
    /// 不是主播才调[exitReport-退出直播上报]，主播会调停止直播
    if (isAnchor) {
      /// 是主播，这里什么都不用做，
      /// 因为[anchorCloseRoom]包含"统计上报"与"移除IM消息回调"等
      return;
    }

    // 统计上报
    await setLiveExit();
    // FB 用户退出上报
    fbApiExitLiveRoom();
    // 移除IM消息回调
    fbApiRemoveLiveMsgHandler();
  }

  //2、注册回调
  void fbApiRegisterMsgHandler() {
    fbApi.registerLiveMsgHandler(this);
  }

  //3、移除回调
  void fbApiRemoveLiveMsgHandler() {
    fbApi.removeLiveMsgHandler(this);
  }

  // 上报当前角色离开直播间
  Future setLiveExit() async {
    await Api.liveExit(widgetRoomId, liveValueModel!.zegoTokenModel?.userToken,
        widgetIsAnchor!, getRoomInfoObject!);
  }

  // FBAPI--用户进入房间
  Future fbApiEnterLiveRoom() async {
    if (isOverlayViewPushValue != null && isOverlayViewPushValue!) {
      /// 来自悬浮窗，不发送进入房间消息。【2021 10.27】
      return;
    }
    await fbApi.enterLiveRoom(
        getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel?.roomId ?? widgetRoomId!,
        isAnchor,
        getRoomInfoObject!.serverId,
        isOverlayViewPush ?? false);
  }

  // FBAPI--用户退出房间
  void fbApiExitLiveRoom() {
    fbApi.exitLiveRoom(
        getRoomInfoObject!.serverId,
        getRoomInfoObject!.channelId,
        liveValueModel!.zegoTokenModel?.roomId ?? widgetRoomId!);
  }

  // FBAPI--发送弹幕消息
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

  // FBAPI--消息格式组装
  static String _formatMsgJSON(String content) {
    final Map msgJSON = {};
    msgJSON['content'] = content;
    return json.encode(msgJSON);
  }

  //在线人数数量
  Future getOnLineCount() async {
    /// 确保是直播页面才去查询在线人数
    /// 【2021 11.23】2. 小窗口列表页，出现了直播间的网络提示，不应该。
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

  // 主播关闭直播
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
      /// 【2022 01.25】关闭直播失败处理
      await closeFail();
    }
  }

  // 主播直播结束-主播跳转
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

  /// 收到商品推送
  @override
  void onGoodsNotice(FBUserInfo user, String type, String json) {
    onGoodsNoticeHandle(user, type, json, widgetIsAnchor, widgetRoomId);
  }

  /// 收到聊天弹幕消息
  /// @param user: 发送弹幕消息的用户
  /// @param json: 发送弹幕消息时的自定义消息
  @override
  void onReceiveChatMsg(FBUserInfo user, String json) {
    final Map textMap = jsonDecode(json);
    final String? text = textMap["content"];
    final Map chatMap = {"user": user, "text": text, "type": "user_chat"};
    liveValueModel!.chatList.add(chatMap);
    chartEventBus.fire(LiveRoomChartEvent(liveValueModel!.chatList));

    /// 没有关闭的时候才去添加
    if (!chatListBlocModel!.isClosed) {
      chatListBlocModel?.add(chatMap);
    }
  }

  /// 收到送礼消息
  /// @param user: 送礼物的用户
  /// @param json: 发送礼物消息时的自定义消息
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

  /// 用户进入直播间
  /// @param user: 进入直播间的用户
  @override
  void onUserEnter(FBUserInfo user) {
    if (user.userId != getRoomInfoObject!.anchorId) {
      //用户进入直播间
      final Map chatMap = {"user": user, "text": "来了", "type": "user_coming"};
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

  /// 用户退出直播间
  /// @param user: 退出直播间的用户
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
      /// 修复【用户退出直播间】报错null
      onlineUserCountModel?.users?.forEach((element) {
        if (element.userId == user.userId) {
          getOnLineCount();
        }
      });
    }
  }

  // 踢出服务器
  @override
  void onKickOutOfGuild() {
    if (!isAnchor) {
      return;
    }
    liveValueModel!.liveStatus = LiveStatus.kickOutServer;
    eventBus.fire(LiveStatusEvent(LiveStatus.kickOutServer));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        myToastLong('您已被管理员踢出服务器。如果有疑问，请联系管理员',
            duration: const Duration(days: 1)); // 固定半透明
      });
      // 延迟3S,关闭直播间
      Future.delayed(const Duration(seconds: 3), anchorCloseRoom);
    }
  }

  // 主播开始直播
  Future anchorStartLive() async {
    final Map status = await Api.starteLive(widgetRoomId!);
    if (status['code'] == 200) {
      liveValueModel!.liveStatus = LiveStatus.openLiveSuccess;
      eventBus.fire(LiveStatusEvent(LiveStatus.openLiveSuccess));

      /// 已采用状态管理，暂时隐藏setState
      isStartLive = false;
      roomBottomBlocModel!.add(true);
      // 通知服务端
      await setLiveEnter();
      if (anchorIsObs) {
        // 通知服务端obs开始直播
        await setLiveObsStart();
      }
      // 通知FB
      await fbApiEnterLiveRoom();

      // 检测直播带货
      await goodsApi(widgetRoomId!, this);

      if (anchorIsObs) {
        // 【APP】第一次：IOS端OBS推流直播，私聊观众，然后点击右侧小窗口回到直播间，主播端黑屏
        livePreviewBlocModel!.add(0);
      }
    } else {
      liveValueModel!.liveStatus = LiveStatus.openLiveFailed;
      eventBus.fire(LiveStatusEvent(LiveStatus.openLiveFailed));
      if (!isShowOverlayView || routeHasLive) {
        showConfirmDialog(() {
          Loading.showConfirmDialog(
              context!,
              // TODO 后续 obs这里的业务逻辑要根据产品修改
              (liveValueModel?.getIsObs ?? false)
                  ? {
                      'content': '外部直播软件是否开启推流',
                      'cancelText': '退出',
                      'confirmText': '重试'
                    }
                  : {
                      'content': '出现故障，直播失败',
                      'cancelText': '退出',
                      'confirmText': '重试'
                    },
              anchorStartLive, cancelCallback: () {
            goBack();
          });
        });
      }
    }
  }

  // 上报当前角色进入直播间
  Future setLiveEnter() async {
    final liveEnter = await Api.liveEnter(
        widgetRoomId, liveValueModel!.zegoTokenModel?.userToken);
    if (liveEnter != "" && liveEnter != null) {
      if (liveEnter['code'] == null || liveEnter['code'] == 400) {
        showConfirmDialog(() {
          Loading.showConfirmDialog(
              context!,
              {
                'content': '直播故障，请退出重试',
                'cancelText': '退出',
                'confirmText': '重试',
                'cancelShow': false
              },
              anchorStartLive, cancelCallback: () {
            goBack();
          });
        });
      }
    }

    // 进入直播间日志上报
    if (!widgetIsAnchor! && !isOverlayViewPush! && widgetIsFromList != null) {
      LiveLogUp.liveEnter(widgetIsFromList!, widgetRoomId!,
          getRoomInfoObject!.serverId, getRoomInfoObject!.channelId);
    }

    await getOnLineCount(); //进入直播后查询在线人数
  }

  //即构
  Future<void> getZegoToken() async {
    final Map resultData = await Api.getZegoToken(widgetRoomId!);

    if (resultData["code"] == 200) {
      liveValueModel!.zegoTokenModel =
          ZegoTokenModel.fromJson(resultData["data"]);
      //初始化直播SDK
      if (liveValueModel!.zegoTokenModel!.userId ==
          liveValueModel!.zegoTokenModel!.anchorId) {
        //主播与用户ID一样  主播重新进入
        isAnchor = true;
      } else {
        isAnchor = false;
      }

      await fbApi.setSharePref(
          "live_userToken", liveValueModel!.zegoTokenModel!.userToken!);
    }
  }

  /*
  * 获取当前用户
  * */
  Future getCurrentUser() async {
    try {
      // 获取当前登录用户
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
              'content': '网络出现问题，请退出房间检查网络正常后重新开启直播',
              'confirmText': '退出',
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
  * 清理礼物对象及状态滞空
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

  // 定时查询线上人数
  void startTimerGetOnline() {
    cancelTimer();
    liveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getOnLineCount();
    });
  }

  /*
  * 直播房间信息出错
  * */
  void liveRoomInfoFail() {
    const String roomInfoFailStir = "获取房间信息出现错误";

    myFailToast(roomInfoFailStir);
    fbApi.fbLogger.info(roomInfoFailStir);

    // 防止直播视图一直无内容
    livePreviewBlocModel!.add(0);
  }

  // 清除定时器
  void cancelTimer() {
    liveTimer?.cancel();
  }

  /*
  * 取消订阅及流处理
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
* 直播状态处理
* */
mixin LiveStatusHandle
    on LiveMix, LiveLoadLogic, LiveInterface, LiveLogicCommon {
  void netErrorStatusHandle() {
    Future.delayed(Duration.zero, () {
      Loading.showConfirmDialog(
          context!,
          {
            'content': '网络出现问题，请退出房间检查网络正常后重新开启直播',
            'confirmText': '退出',
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
            'content': '网络问题，无法开启直播，退出房间重试',
            'confirmText': '退出',
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
    } // 固定，半透明【刷新】，重新登录房间
  }

  void netConfigStatusHandle() {
    liveValueModel!.liveStatus = LiveStatus.networkError;
    eventBus.fire(LiveStatusEvent(LiveStatus.networkError));
    if (!isShowOverlayView || routeHasLive) {
      myFailToast('网络错误，请检查网络配置', duration: const Duration(days: 1));
    } // 固定，半透明【刷新】，重新登录房间
  }

  void abnormalLoginStatusHandle() {
    // 1002050	用户被踢出房间，可能是相同用户 ID 在其他设备登录
    liveValueModel!.liveStatus = LiveStatus.abnormalLogin;
    eventBus.fire(LiveStatusEvent(LiveStatus.abnormalLogin));
    if (!isShowOverlayView || routeHasLive) {
      showConfirmDialog(() {
        RouteUtil.popToLive();
        Loading.showConfirmDialog(context!, {
          'content': '你的账号当前在另一台设备中登录，如果这不是你本人的操作，请立刻重新登录修改密码',
          'confirmText': '退出',
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
            {'content': '拉流失败，请重试！', 'confirmText': '确认', 'cancelShow': false},
            setStreamAndTexture);
      });
    }
  }

  void offlineStatusHandle() {
    showConfirmDialog(() {
      Loading.showConfirmDialog(
          context!,
          {
            'content': '主播已经下线了，感谢你的观看',
            'confirmText': '退出',
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
              'content': '由于直播内容违规，直播已被管理员禁播。如果有疑问，请联系管理员',
              'confirmText': '退出',
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
            {'content': '直播超时已自动关闭', 'confirmText': '退出', 'cancelShow': false},
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
              'content': '由于直播内容违规，直播已被系统禁播。如果有疑问，请联系管理员',
              'confirmText': '退出',
              'cancelShow': false
            },
            goBack);
      });
    }
  }
}
