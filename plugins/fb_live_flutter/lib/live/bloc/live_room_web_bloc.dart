import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/overlay_web_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/model/zego_token_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room_web.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:flutter/material.dart';
import 'package:zego_ww/zego_ww.dart';

import 'logic/goods_logic.dart';

class LiveRoomWebBloc extends BaseAppCubit<int>
    with
        BaseAppCubitState,
        LiveLoadInterface,
        LiveShopInterface,
        LiveInterface,
        LiveLoadWith,
        LiveMix,
        GoodsLogic {
  LiveRoomWebBloc() : super(0);

  StreamSubscription? _showOverlayViewSus;
  RoomInfon? roomInfon; //房间信息对象

  late ZegoTokenModel zegoTokenModel;

  bool isShowOverlayView = true;

  late State<LiveRoomWeb> statePage;

  ZegoWwMediaModel? mediaModel;
  ZegoWwVideoView? videoView;

  void init() {
    //上报用户信息
    saveUserInfo(fbApi.getCurrentChannel()!.guildId);

    _showOverlayViewSus =
        EventBusManager.eventBus.on<OverlayWebModel>().listen((event) {
      showOverlayView(FBLiveEvent.gotoChat);
    });
  }

  State<LiveRoomWeb> statePageProperty(State<LiveRoomWeb> state) {
    return statePage = state;
  }

  @override
  BuildContext get context {
    return statePage.context;
  }

  bool? get isAnchorValue {
    return statePage.widget.isAnchor;
  }

  void showOverlayView(FBLiveEvent event) {
    isShowOverlayView = true;
    RouteUtil.pop();

    // web不存在悬浮窗，只有画中画
  }

  @override
  Future<void> close() {
    _showOverlayViewSus?.cancel();
    _showOverlayViewSus = null;
    return super.close();
  }

  @override
  Future getRoomInfo() async {}

  @override
  bool get mounted => statePage.mounted;

  @override
  Future checkMirrorMode() async {
    fbApi.fbLogger.info("checkMirrorMode::web无需处理");
  }

  @override
  Future<BuildContext?> rotateScreenExec(BuildContext? context) async {
    fbApi.fbLogger.info("rotationHandle::web无需处理");
    return context;
  }

  @override
  Future rotationHandle([bool? value]) async {
    fbApi.fbLogger.info("rotationHandle::web::等待处理");
  }

  @override
  Future<void> authCheck(BuildContext context, VoidCallback onTap) async {
    fbApi.fbLogger.info("authCheck::web::等待处理");
  }

  @override
  Future commerce2(String? roomId, {VoidCallback? onComplete}) async {
    fbApi.fbLogger.info("commerce2::web::等待处理");
  }

  @override
  Future setStreamAndTexture() async {
    fbApi.fbLogger.info("setStreamAndTexture::web::等待处理");
  }

  @override
  String get roomId => statePage.widget.liveValueModel!.roomInfoObject!.roomId;
}
