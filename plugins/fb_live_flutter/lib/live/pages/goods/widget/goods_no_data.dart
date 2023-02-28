import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/coupons_add_dialog.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/create_room_button.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';

/// 商品货架暂无商品-视图
class GoodsNoData extends StatelessWidget {
  final bool? isHaveButton;
  final GestureTapCallback? onTap;
  final String? text;
  final String? btText;

  const GoodsNoData({this.isHaveButton, this.onTap, this.text, this.btText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FrameSize.winWidth(),
      padding: EdgeInsets.only(bottom: 50.px),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwImage(
            'assets/live/main/goods_no_ata.png',
            width: 160.px,
            height: 160.px,
          ),
          Text(
            /// 【2021 11.24】[x] @王增阳 暂无数据系列ui更新
            text ?? "商品货架暂无商品",
            style: TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
          ),
          Space(height: 43.px),
          if (isHaveButton ?? false)
            CreateRoomButton(
              title: btText ?? "从店铺添加商品",
              size: Size(170.px, 36.5.px),
              circular: 18.25.px,
              onTap: () {
                if (onTap != null) {
                  onTap!();
                }
              },
            )
          else
            Container(),
        ],
      ),
    );
  }
}

/// 优惠券暂无商品-视图
class CouponsNoData extends StatelessWidget {
  final bool? isAdmin;
  final List<CouponListModel> models;
  final GoodsLogic goodsLogic;

  const CouponsNoData(this.isAdmin, this.models, this.goodsLogic);

  @override
  Widget build(BuildContext context) {
    return GoodsNoData(
      text: "暂无优惠券",
      btText: '添加优惠券',
      isHaveButton: isAdmin,
      onTap: () {
        couponsAddDialog(context, false, models, goodsLogic);
      },
    );
  }
}
