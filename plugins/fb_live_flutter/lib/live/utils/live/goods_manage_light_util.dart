import 'dart:ui';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/goods/goods_cart_light_model.dart';

class GoodsManageCartUtil {
  static GoodsCartLightModel? goodsCartLightModel;

  /*
  * 设置内存存储的数量
  * */
  static Future<void> setCount(
      int cartCount, bool isShow, VoidCallback onSet, String roomId) async {
    if (goodsCartLightModel == null) {
      if (isShow) {
        onSet();
      }
      goodsCartLightModel = GoodsCartLightModel(
        roomId: roomId,
        isShow: isShow ? "1" : "2",
        cartCount: "$cartCount",
        userId: fbApi.getUserId(),
      );
      return;
    }
    if (goodsCartLightModel!.isShow == "1") {
      onSet();
      goodsCartLightModel!.isShow = '1';
      goodsCartLightModel!.cartCount = "$cartCount";
      return;
    }
  }

  /*
  * 添加购物车存储
  * */
  static Future<void> addCount(int cartCount, String roomId) async {
    goodsCartLightModel = GoodsCartLightModel(
      roomId: roomId,
      isShow: "1",
      cartCount: "$cartCount",
      userId: fbApi.getUserId(),
    );
  }

  /*
  * 已读回执存储
  * */
  static Future<void> readCount(int cartCount, String roomId) async {
    goodsCartLightModel = GoodsCartLightModel(
      roomId: roomId,
      isShow: "2",
      cartCount: "$cartCount",
      userId: fbApi.getUserId(),
    );
  }
}
