import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_card.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

/// 优惠券列表-选择框卡片:
/// 主播/小助手可见
typedef GoodsCheckCall = Function(CouponListModel? value);
typedef GoodsCheckValueCall = Function(String value);

class CouponsCheckBox extends StatelessWidget {
  final int rank;
  final GoodsCheckCall? call;
  final bool? isSelect;
  final CouponListModel? item;
  final Widget? titleW;
  final GoodsLogic goodsLogic;

  const CouponsCheckBox(
    this.rank, {
    this.call,
    this.isSelect,
    this.item,
    this.titleW,
    required this.goodsLogic,
  });

  @override
  Widget build(BuildContext context) {
    return ClickEvent(
      onTap: () async {
        if (!(item?.isCanSelect ?? true)) {
          return;
        }
        if (call != null) {
          call!(item);
        }
      },
      child: Container(
        /// [ ] 多选按钮没跟优惠券居中对齐
        /// [2021 11.20]
        margin: EdgeInsets.only(bottom: 10.px),
        child: Row(
          children: [
            Space(width: 12.px),

            ///  多选按钮模糊找俊杰要多选的组件
            ///  [2021 11.29]是否选中【禁用状态】使用已选择的多选框
            checkboxIcon(
              isSelect! || !(item?.isCanSelect ?? true),
              disabled: !(item?.isCanSelect ?? true),

              /// 多选按钮大小[2021 12.1]
              size: 18.33.px,
            ),
            Space(width: 2.px),
            Expanded(
              child: CouponsCard(
                rank,
                item,
                space: 12.px + 22.px + 2.px,
                roomInfoObject: goodsLogic.getRoomInfoObject!,
                goodsLogic: goodsLogic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
