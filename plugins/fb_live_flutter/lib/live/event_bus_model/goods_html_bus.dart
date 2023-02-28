import 'package:event_bus/event_bus.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';

EventBus goodsHtmlBus = EventBus();

class GoodsHtmlEvenModel {
  final int index;

  GoodsHtmlEvenModel(this.index);
}

/// 【2021 12.13】不局限于iOS了，Android也同样
class GoodsIosShowWindowEvenModel {
  final bool isShow;

  GoodsIosShowWindowEvenModel(this.isShow);
}

/// 主播推送商品后自己需要收到商品推送
EventBus goodsAnchorPushBus = EventBus();

class GoodsPushEvenModel {
  final String json;
  final String type;
  final FBUserInfo user;

  GoodsPushEvenModel({
    required this.json,
    required this.type,
    required this.user,
  });
}
