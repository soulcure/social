import 'package:fb_live_flutter/live/bloc/logic/coupons_logic.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc_model/shop_bloc_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget/animate/coupons_icon.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 优惠券入口[组件]
///
/// 【APP】非带货直播，出现优惠券
///
/// 关于优惠券ico显示规则：
/// 1. 观众与主播/助理，显示不同的ico，主播/助理是显示文字ico
/// 2. 主播/助理 的ico 是常驻显示的。
/// 3. 观众端一开始是没有ico的，只当主播/助手添加了优惠券之后，观众端就会及时显示ico，而且不再消失（哪怕优惠券被抢完了，或者管理员再删除了优惠券，都不会消失）直到退出直播。
/// 4. 新进来的观众的，如果是有优惠券，那及时显示优惠券ico，如果直播间里还没有设置优惠券，那不显示优惠券ico。
class CouponsBt extends StatefulWidget {
  final LiveInterface liveBloc;
  final GoodsLogic goodsLogic;
  final LiveShopInterface liveShopInterface;
  final CouponsLogic couponsLogic;
  final LiveValueModel liveValueModel;

  const CouponsBt({
    required this.liveBloc,
    required this.goodsLogic,
    required this.liveShopInterface,
    required this.couponsLogic,
    required this.liveValueModel,
  });

  @override
  _CouponsBtState createState() => _CouponsBtState();
}

class _CouponsBtState extends State<CouponsBt>
    with AutomaticKeepAliveClientMixin {
  bool get isObs {
    return widget.liveBloc.getRoomInfoObject!.liveType == 3;
  }

  bool? get isAnchor {
    return widget.liveBloc.isAnchor;
  }

  bool get isAssistantValue {
    return widget.goodsLogic.isAssistantValue ?? false;
  }

  /*
  * 是否管理人员
  * */
  bool get isAdmin {
    return isAnchor! || isAssistantValue;
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  /// 初始化直播小助手
  Future<void> init() async {
    widget.goodsLogic.isAssistantValue ??= await widget.goodsLogic
        .isAssistant(widget.liveBloc.getRoomInfoObject!.roomId);
    GoodsLogicValue.isAssistantValue = widget.goodsLogic.isAssistantValue;
    if (mounted) setState(() {});
  }

  Future<void> action() async {
    final contextValue = await widget.liveBloc.rotateScreenExec(context);
    if (contextValue == null) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 80));
    if (FrameSize.isHorizontal()) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await widget.liveShopInterface.authCheck(contextValue, () async {
      await widget.couponsLogic.toCouponsDialog(
          contextValue,
          widget.liveBloc.isAnchor,
          widget.liveBloc.getRoomInfoObject!.roomId,
          widget.goodsLogic);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bool isScreenRotation = widget.liveBloc.isScreenRotation;
    final bool isShowRotationButton = widget.liveBloc.isShowRotationButton;

    /// [2021 12.30]
    /// 7. 间距40px
    final firstTop = (!isScreenRotation
            ? FrameSize.padTopH() + FrameSize.px(11)
            : FrameSize.px(11)) +
        30.px +
        20.px;

    final double? top =
        !isShowRotationButton ? firstTop : firstTop + 30.px + 20.px;

    return Positioned(
      top: top,

      /// [2021 11.25] [ ] 观众端优惠券ICO放大。
      left: !isAdmin ? null : FrameSize.px(12),
      child: BlocBuilder<CouponsBlocModelQuick, CouponsState?>(
        builder: (context, couponsState) {
          /// 除了初始化第一帧，实际无任何地方传递null
          if (couponsState == null) {
            return Container();
          }

          /// 数量如果传空则不影响原始的[isShowCoupons]
          if (couponsState.isShowCoupons != null) {
            widget.liveValueModel.isShowCoupons = couponsState.isShowCoupons;
          }

          /// 如果不是主播且不是小助手且优惠券数量为0 [isShowCoupons为false] 不显示优惠券入口
          final bool isShowContainer =
              !widget.liveBloc.isAnchor && !isAssistantValue;
          if (isShowContainer && !widget.liveValueModel.isShowCoupons!) {
            return Container();
          }

          if (!isAdmin) {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,

              /// 【2021 12.28】优惠券图标适配有左右安全区时
              padding: EdgeInsets.only(
                  right: FrameSize.padLeft() + FrameSize.padRight()),

              /// 横屏如果不加颜色会不显示icon
              color: FrameSize.isHorizontal() ? Colors.transparent : null,
              child: Stack(
                children: [
                  CouponsIcon(
                    /// [2021 12.25] 不使用top了，状态难以维护
                    0,
                    onTap: action,
                    isNeedAnimate: !FrameSize.isHorizontal(),
                  ),
                ],
              ),
            );
          }

          /// 主播和小助手的优惠券显示入口组件
          return ClickEvent(
            ///  【主播&&小助手】和观众的直播优惠券入口ui要不同的
            ///  [2021 11.12]
            onTap: action,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.px),
              height: 24.px,
              decoration: BoxDecoration(
                  color: const Color(0xff000000).withOpacity(0.25),
                  borderRadius: const BorderRadius.all(Radius.circular(18))),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    '设置优惠券',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.px,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Image.asset(
                    'assets/live/main/coupons_main_arrow.png',
                    width: 10.px,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}
