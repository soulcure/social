import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_card.dart';

class CouponListModel {
  int? shopId;
  int? id;
  int? type;
  String? typeStr;
  String? title;
  String? description;
  String? usingLimit;
  String? timeRule;
  String? value;
  String? minValue;
  String? maxValue;
  int? stockQty;
  CouponsStatus? status;
  CouponsType? couponsType;
  bool? isCanSelect;
  RxBool? isExpanded;
  bool? checked;

  CouponListModel({
    this.shopId,
    this.id,
    this.type,
    this.couponsType,
    this.isCanSelect = true,
    this.title,
    this.description,
    this.usingLimit,
    this.timeRule,
    this.value,
    this.minValue,
    this.maxValue,
    this.stockQty,
    this.status,
    this.typeStr,
    this.isExpanded,
    this.checked,
  });

  /*
  * 获取类型文字
  * */
  String getTypeStr(int? type) {
    switch (type) {
      case 1:
        return "满减券";
      case 2:
        return "折扣券";
      case 3:
        return "随机金额券";
      default:
        return "未知";
    }
  }

  /*
  * 获取类型枚举
  * */
  CouponsType getTypeEnum(int? type) {
    switch (type) {
      case 1:
        return CouponsType.fullReduction;
      case 2:
        return CouponsType.discount;
      case 3:
        return CouponsType.random;
      default:

        /// 默认
        return CouponsType.fullReduction;
    }
  }

  CouponListModel.fromJson(Map<String, dynamic> json) {
    shopId = json['shopId'];
    id = json['id'];
    type = json['type'];
    typeStr = getTypeStr(type);
    couponsType = getTypeEnum(type);
    title = json['title'];
    description = json['description'];
    usingLimit = json['usingLimit'];
    timeRule = json['timeRule'];
    value = json['value'];
    minValue = json['minValue'];
    maxValue = json['maxValue'];
    stockQty = json['stockQty'];
    status = json['status'] != null
        ? CouponsStatus.values[json['status']]
        : stockQty! > 0
            ? CouponsStatus.ok
            : CouponsStatus.gone;
    isExpanded = false.obs;

    checked = json['checked'];
    if (checked != null) {
      isCanSelect = !checked!;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shopId'] = shopId;
    data['id'] = id;
    data['type'] = type;
    data['title'] = title;
    data['description'] = description;
    data['usingLimit'] = usingLimit;
    data['timeRule'] = timeRule;
    data['value'] = value;
    data['minValue'] = minValue;
    data['maxValue'] = maxValue;
    data['stockQty'] = stockQty;
    data['status'] = status!.index;
    data['checked'] = checked;
    return data;
  }
}
