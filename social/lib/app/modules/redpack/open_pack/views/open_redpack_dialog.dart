/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/views/open_redpack_dialog.dart
 * 
 * @Info           : 红包弹窗：1、待打开红到样式，2、过期和已领完样式
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-06 10:39:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-25 15:48:47
 * 
 */

import 'package:animations/animations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/redpack/open_pack/components/redpack_transition_configuration.dart';
import 'package:im/app/modules/redpack/open_pack/controllers/open_redpack_controller.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_info_ben.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_util.dart';
import 'package:im/app/modules/redpack/send_pack/data/grab_redpack_resp.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/utils/sound_manager.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/rive/speed_controller.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rive/rive.dart';

class OpenRedPackDialog {
  /// 单例模式：私有创建方法
  OpenRedPackDialog._internal();

  ///
  /// 展示弹窗：打开红包
  ///
  /// - status: 弹窗展示类型 [RedPackStatus]
  /// - detail: 红包详情数据
  ///
  /// Return: null
  ///
  static Future<void> open(int status,
      {@required BuildContext context,
      @required OpenRedPackDetailModel detail}) async {
    //  直接跳转至红包详情：
    //  - 1、私信里自己的红包
    //  - 2、已领取
    if ((Global.user.id == detail.userId && detail.isDmRedPack) ||
        status == RedPackStatus.GrabbedRedPack) {
      await OpenRedPackController.requestRedPackDetail(context, detail);
      return;
    }
    //  静态对象：
    final GlobalKey<_OpenRedPackDialogChildState> redPackDetailGK =
        GlobalKey<_OpenRedPackDialogChildState>();
    //  展示抢红包弹窗页面：
    const transitionDuration = Duration(milliseconds: 500);
    final popTime = DateTime.now();
    final result = await showModal(
        context: context,
        configuration: RedPackTransitionConfiguration(
            transitionDuration: transitionDuration),
        builder: (_) {
          return WillPopScope(
            onWillPop: () async {
              if (DateTime.now().subtract(transitionDuration).isBefore(popTime))
                return false;
              return !redPackDetailGK.currentState.isOpeningRedPack;
            },
            child: AlertDialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              content: _OpenRedPackDialogChild(status,
                  fromPage: Get.currentRoute,
                  detail: detail,
                  key: redPackDetailGK),
            ),
          );
        });
    if (true == result) {
      /// NOTE: 2022/1/19 总是优先领红包操作，通过服务端返回领红包错误码去决定
      await ServerSideConfiguration.to.isBindAliPay(context);
    }
  }
}

// ignore: must_be_immutable
class _OpenRedPackDialogChild extends StatefulWidget {
  /// 红包领取状态
  final int status;

  /// 红包详情
  final OpenRedPackDetailModel detail;

  /// 来自那个页面
  final String fromPage;

  /// 构造函数
  const _OpenRedPackDialogChild(
    this.status, {
    Key key,
    @required this.fromPage,
    @required this.detail,
  }) : super(key: key);

  @override
  _OpenRedPackDialogChildState createState() => _OpenRedPackDialogChildState();
}

/// 红包弹窗样式
// ignore: must_be_immutable
class _OpenRedPackDialogChildState extends State<_OpenRedPackDialogChild>
    with TickerProviderStateMixin {
  /// 当前状态
  int currentStatus;

  /// 动画控制器：
  AnimationController _redPackCoverAnimaCtl;

  /// 开红包封面：背景逐渐透明
  Animation<double> graduallyFadeAnima;

  /// 开红包背景：封面变大
  Animation<double> bigScaleAnima;

  /// 开红包封面：向上动画
  Animation<Offset> toTopAnima;

  /// 开红包封面：向下动画
  Animation<Offset> toBottomAnima;

  /// 金币动画控制器
  RiveAnimationController _goldCoinsAnimaCtl;

  /// 是否正在开红包(金币转动说明是在开红包)
  bool get isOpeningRedPack => _goldCoinsAnimaCtl.isActive;

  /// 开红包成功音效播放器
  AudioPlayer openSuccessAP;

  // ====== Override Method: Parent ====== //

  @override
  void initState() {
    //  初始化当前状态
    currentStatus = widget.status;
    //  创建动画效果
    //  - 初始化红包封面动画控制器
    _redPackCoverAnimaCtl = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    //  -- 动画状态监听：动画完成后跳转至详情页面
    _redPackCoverAnimaCtl.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.completed:
          //  关闭金币动画完成金币动画闭环
          _goldCoinsAnimaCtl.isActive = false;
          //  设置详情需要动画
          widget.detail.isNeedAnimation = true;
          //  由于弹窗之上可能存在其它仍能执行操作的页面，防止无法关闭红包弹窗
          Get.offNamedUntil(Routes.OPEN_RED_PACK_ANIMA, (route) {
            return route?.settings?.name == widget.fromPage;
          }, arguments: widget.detail);
          break;
        default:
          break;
      }
    });
    //  -- 透明动画
    graduallyFadeAnima =
        Tween<double>(begin: 1, end: 0).animate(_redPackCoverAnimaCtl);
    //  -- 变大动画
    bigScaleAnima =
        Tween<double>(begin: 1, end: 1.55).animate(_redPackCoverAnimaCtl);
    //  -- 红包向下动画
    toTopAnima = Tween(begin: Offset.zero, end: const Offset(0, -2))
        .animate(_redPackCoverAnimaCtl);
    //  -- 红包向上动画
    toBottomAnima = Tween(begin: Offset.zero, end: const Offset(0, 3))
        .animate(_redPackCoverAnimaCtl);
    //  - 初始化金币动画
    _goldCoinsAnimaCtl =
        SpeedController("Animation 1", speedMultiplier: 0.75, autoplay: false);
    _goldCoinsAnimaCtl.isActive = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 300,
        height: 480,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          clipBehavior: Clip.none,
          children: [
            //  红包封面:上下两部分
            Positioned(
                top: 0,
                child: ScaleTransition(
                    scale: bigScaleAnima,
                    child: SlideTransition(
                      position: toTopAnima,
                      child: Image.asset(
                        'assets/images/rep_pack_cover_top.png',
                        width: 300,
                        height: 395,
                        fit: BoxFit.fill,
                      ),
                    ))),
            Positioned(
                bottom: 0,
                child: ScaleTransition(
                    scale: bigScaleAnima,
                    child: SlideTransition(
                      position: toBottomAnima,
                      child: Image.asset(
                        'assets/images/rep_pack_cover_bottom.png',
                        width: 300,
                        height: 140,
                        fit: BoxFit.fill,
                      ),
                    ))),
            //  红包顶层内容：用户信息，红包信息
            Column(
              children: [
                // - 用户头像和昵称
                Expanded(
                  child: SlideTransition(
                    position: toTopAnima,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 48,
                        ),
                        RealtimeAvatar(
                          userId: widget.detail.userId,
                          size: 48,
                          showBorder: false,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "%s 发出的红包".trArgs([widget.detail.userName]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: goldColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        // - 红包备注
                        Expanded(
                          child: _assembleRedPackRemark(),
                        ),
                      ],
                    ),
                  ),
                ),
                // - 开红包按钮
                Visibility(
                  // -- 只有在status为newRedPack的情况下展示开红包按钮
                  visible: currentStatus == RedPackStatus.newRedPack,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 必须要有一次初始化，所以只能用Visibility
                      Container(
                          width: 95.5,
                          height: 95.5,
                          alignment: Alignment.center,
                          child: RiveAnimation.asset(
                            'assets/rive/gold_coins.riv',
                            controllers: [_goldCoinsAnimaCtl],
                          )),
                      Visibility(
                        visible: !_goldCoinsAnimaCtl.isActive,
                        child: Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: goldColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Get.textTheme.bodyText2.color
                                    .withOpacity(0.1),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FadeBackgroundButton(
                            tapDownBackgroundColor:
                                Colors.black.withOpacity(0.1),
                            onTap: () => openRedPackAction(context),
                            child: const Icon(
                              IconFont.buffIconOpen,
                              size: 48,
                              color: redDeepTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                _assembleRedPackLookMore(),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _redPackCoverAnimaCtl?.dispose();
    _goldCoinsAnimaCtl?.dispose();
    openSuccessAP?.stop();
    openSuccessAP?.dispose();
    super.dispose();
  }

  // ====== Method - Self: Private ====== //

  /// 组装视图：红包备注/问候
  Widget _assembleRedPackRemark() {
    String redPackRemark = widget.detail.remark;
    switch (currentStatus) {
      case RedPackStatus.expiredRedPack:
        redPackRemark = "超过24小时未领取，红包已过期".tr;
        break;
      case RedPackStatus.noneLeftRedPack:
        redPackRemark = "手慢了，红包已领完".tr;
        break;
      default:
        break;
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          redPackRemark,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: goldColor,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
          ),
        ));
  }

  /// 组装视图：看看大家手气
  /// - 1、私信：对方领到过期红包
  /// - 2、群红包：
  /// - - 2.1、已过期，已领完 查看更多
  /// - - 2.2、自己的查看更多
  /// - 3、如果开红包动画在执行也不展示
  Widget _assembleRedPackLookMore() => (widget.detail.isDmRedPack &&
              currentStatus == RedPackStatus.expiredRedPack) ||
          !widget.detail.isDmRedPack &&
              (Global.user.id == widget.detail.userId ||
                  currentStatus == RedPackStatus.expiredRedPack ||
                  currentStatus == RedPackStatus.noneLeftRedPack)
      ? Visibility(
          visible: !_redPackCoverAnimaCtl.isAnimating,
          child: GestureDetector(
              onTap: jumpToRedPackDetailPage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("看看大家的手气".tr,
                      style: const TextStyle(
                        color: goldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      )),
                  const SizedBox(width: 2),
                  const Icon(
                    IconFont.buffXiayibu,
                    size: 12,
                    color: goldColor,
                  ),
                ],
              )))
      : const SizedBox(
          height: 12,
        );

  /// 开红包逻辑
  Future<void> openRedPackAction(BuildContext context) async {
    //  防止二次点击
    if (_goldCoinsAnimaCtl.isActive) {
      return;
    }
    setState(() {
      //  正在执行动画
      _goldCoinsAnimaCtl.isActive = true;
    });
    //  1、请求接口信息
    bool isUnbind = true;
    final GrabRedPackResp resp = await RedPackAPI.grabRedPacketKey(
            widget.detail.guildId,
            widget.detail.channelId,
            widget.detail.redPackId)
        .catchError((error) {
      if (error.code == 3008) {
        isUnbind = false;
      }
    }).onError((error, stackTrace) {
      logger.warning("openRedPackAction: error=$error");
      return null;
    });
    //  2、如果为空就不执行任何操作，展示服务器返回的结果
    if (resp == null) {
      //  恢复显示按钮样式
      setState(() {
        _goldCoinsAnimaCtl.isActive = false;
      });
      if (!isUnbind) {
        /// NOTE: 2022/1/19 result: true，需要弹出”点亮红包“功能
        Get.back(result: true);
      }
      return;
    }
    //  3、处理获取成功的情况
    //  - 3.1、获取红包状态
    final int flag = resp.flag ?? 0;
    final String subMoney = resp.subMoney ?? '0.00';
    //  - 3.2、刷新会话列表状态
    RedPackUtil().putRedPack(widget.detail.channelId, widget.detail.messageId,
        widget.detail.redPackId, flag, subMoney);
    //  修改为只要抢过红包 都表态
    //if (flag == RedPackStatus.GrabbedRedPack) {
    //给红包消息表态爱心
    unawaited(widget?.detail?.messageEntity?.reactionModel?.addReaction("爱心"));
    //}
    //  - 3.3、领取成功就执行红包打开动画并跳转至红包页面，其它情况刷新弹窗状态
    //  -- 此处刷新红包状态
    currentStatus = flag;
    if (flag != RedPackStatus.GrabbedRedPack) {
      //  更新页面
      setState(() {
        _goldCoinsAnimaCtl.isActive = false;
      });
      return;
    }
    //  - 3.5、设置当前用户已领取的红包金额
    widget.detail.collectedMoney = resp.subMoney;
    //  4、获取红包详情数据
    final OpenRedPackDetailModel newDetail =
        await OpenRedPackController.requestRedPackDetail(context, widget.detail,
            isNeedLoading: false);
    //  - 4.1、出现错误就刷新页面即可
    if (newDetail == null) {
      //  更新页面
      setState(() {
        _goldCoinsAnimaCtl.isActive = false;
      });
      return;
    }
    //  - 4.2、执行音频播放
    openSuccessAP =
        await SoundManager.playSound("sound/open_redpack_success.mp3");
    //  -- 延迟时间让音乐有足够加载和播放时间（1s）
    await Future.delayed(const Duration(milliseconds: 300));
    //  - 4.3、更新页面并好执行动画
    setState(() {
      _redPackCoverAnimaCtl.forward();
    });
  }

  /// 页面跳转：领红包详情页
  Future<void> jumpToRedPackDetailPage() async {
    if (_goldCoinsAnimaCtl.isActive) {
      return;
    }
    Get.back();
    await OpenRedPackController.requestRedPackDetail(context, widget.detail);
  }
}
