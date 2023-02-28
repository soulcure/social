import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc_model/show_image_filter_bloc_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:flutter/material.dart';

/*
* 【直播带货】接口
* */
abstract class LiveShopInterface {
  //是否是主播
  late bool isAnchor;

  // 来自[GoodsLogic]
  bool? isAssistantValue;

  // 来自[GoodsLogic]
  int? shopId;

  /*
  * 房间id，必须初始化立刻赋值，不能为空
  * */
  String get roomId;

  Future<void> authCheck(BuildContext context, VoidCallback onTap);

  Future commerce2(String? roomId, {VoidCallback? onComplete});
}

/*
* 【直播-更多】接口
* */
abstract class LiveMoreInterface {
  /*
  * 显示"正在屏幕共享"ui
  * */
  ShowScreenSharingBlocModel? showScreenSharingBlocModel;

  /*
  * 显示图片遮罩
  * */
  ShowImageFilterBlocModel? showImageFilterBlocModel;

  /*
  * 是否屏幕共享进程中
  * */
  bool isScreenProcess = false;

  /*
  * 是否来自悬浮窗且第一次屏幕共享转换
  * */
  bool? isFromOverlayFirstScreen;

  /*
  * 刷新直播视图
  * */
  Future refreshLiveView();

  /*
  * 状态刷新
  * */
  void onRefresh();
}

abstract class LiveInterface {
  //判断手机屏幕是否旋转
  bool isScreenRotation = false;

  //分享类型：0-不分享、1-分享
  int? shareType;

  //是否已经开启直播
  bool isStartLive = true;

  //是否是主播
  late bool isAnchor;

  // 上下文
  BuildContext? context;

  //判断是否是小窗口进入
  bool? isOverlayViewPush;

  //直播值
  LiveValueModel? liveValueModel;

  //房间对象获取
  RoomInfon? get getRoomInfoObject => liveValueModel?.roomInfoObject;

  /// isShowRotationButton来自判断旋转按钮是否显示，
  bool get isShowRotationButton {
    return ((liveValueModel!.playerVideoWidth >
                liveValueModel!.playerVideoHeight) ||
            liveValueModel!.screenDirection != "V" ||
            isScreenRotation) &&

        /// 【2021 12.28】
        /// 因为主播没有旋转按钮
        /// 【APP】主播/助手obs横屏开播，小窗口返回直播间，设置优惠券下移
        !isAnchor;
  }

  /*
  * 屏幕旋转处理
  * */
  Future rotationHandle([bool? value]);

  /*
  * 校验镜像模式
  * */
  Future checkMirrorMode();

  /*
  * 旋转屏幕再执行
  * */
  Future<BuildContext?> rotateScreenExec(BuildContext? context);

  /*
  * 设置视图画面
  * */
  Future setStreamAndTexture();
}
