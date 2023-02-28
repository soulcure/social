import 'dart:async';

import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/bloc_model/shop_bloc_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods/goods_count_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_dialog.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_manage_dialog.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopWidget extends StatefulWidget {
  final LiveShopInterface liveShop;
  final LiveInterface liveBloc;
  final EdgeInsetsGeometry? margin;
  final GoodsLogic goodsLogic;

  const ShopWidget(
    this.liveShop,
    this.liveBloc, {
    this.margin,
    required this.goodsLogic,
  });

  @override
  State<ShopWidget> createState() => _ShopWidgetState();
}

class _ShopWidgetState extends State<ShopWidget> {
  StreamSubscription? _countSub;

  Future toManage(BuildContext context) {
    return goodsManageDialog(context, widget.liveShop.isAnchor,
        widget.goodsLogic.getRoomInfoObject!);
  }

  @override
  void initState() {
    super.initState();
    _countSub = goodsCountBus.on<GoodsCountModel>().listen((event) {
      widget.liveBloc.liveValueModel!.goodsCount = event.count;
      if (mounted) setState(() {});
    });
  }

  Future<void> toDialog() async {
    final contextValue = await widget.liveBloc.rotateScreenExec(context);
    if (contextValue == null) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 50));

    /// 商品列表对话框【弹出】
    if (widget.liveShop.isAnchor) {
      await toManage(contextValue);
    } else {
      widget.liveShop.isAssistantValue ??=
          await widget.goodsLogic.isAssistant(widget.liveShop.roomId);
      GoodsLogicValue.isAssistantValue = widget.liveShop.isAssistantValue;
      if (widget.liveShop.isAssistantValue ?? false) {
        await toManage(contextValue);
      } else {
        await goodsDialog(contextValue, widget.liveShop.shopId,
            widget.liveBloc.getRoomInfoObject!);
      }
    }
  }

  Future<void> handle() async {
    if (widget.liveShop.shopId == null) {
      await widget.liveShop.commerce2(widget.liveShop.roomId);
    }

    // 日志上报【点击货架】
    LiveLogUp.clickShoppingCart(widget.goodsLogic.getRoomInfoObject!);

    /// 授权有赞
    ///
    /// @王增阳  与俊杰沟通，用户授权配置，为了我们自己前端测试[11.9]
    await widget.liveShop.authCheck(context, toDialog);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBlocModelQuick, ShopState?>(
      builder: (context, shopState) {
        /// 除了初始化第一帧，实际无任何地方传递null
        if (shopState == null) {
          return Container();
        }

        if (shopState.count != null) {
          widget.liveBloc.liveValueModel!.goodsCount = shopState.count ?? 0;
        }

        return ClickEvent(
          onTap: () {
            try {
              return handle();
            } catch (e) {
              myFailToast('出现错误');
              return Future.value();
            }
          },
          child: Container(
            margin: widget.margin,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Image.asset(
                  'assets/live/main/ic_shop.png',
                  width: 40.px,
                  height: 40.px,
                ),
                Padding(
                  /// 【APP】购物袋数量显示间距问题
                  padding: EdgeInsets.only(bottom: 4.px),
                  child: Text(
                    /// 【APP】观众进入直播间，主播未添加商品时，商品数量不显示
                    /// 2021 11.10
                    '${widget.liveBloc.liveValueModel!.goodsCount == 0 ? "" : widget.liveBloc.liveValueModel!.goodsCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.px,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _countSub?.cancel();
    _countSub = null;
  }
}
