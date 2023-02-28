import 'package:fb_live_flutter/live/pages/coupons/coupons_dialog.dart';
import 'package:flutter/cupertino.dart';

import 'goods_logic.dart';

mixin CouponsLogic on GoodsLogic {
  Future toCouponsDialog(BuildContext context, bool isAnchor, String? roomId,
      GoodsLogic goodsLogic) async {
    /// 优惠券列表对话框【弹出】
    if (isAnchor) {
      /// 如果是主播隐藏优惠券的立即领取
      await couponsDialog(
          context, isAnchor, false, goodsLogic.getRoomInfoObject!, goodsLogic);
    } else {
      isAssistantValue ??= await goodsLogic.isAssistant(roomId);
      GoodsLogicValue.isAssistantValue = isAssistantValue;
      await couponsDialog(context, isAssistantValue, true,
          goodsLogic.getRoomInfoObject!, goodsLogic);
    }
  }
}
