import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_sku_dialog.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';

import 'goods_sku_api.dart';

/// 【2021 12.2】留言相关【商品立即下单&&向购物车添加商品】Api更新
class GoodsSkuBloc extends BaseAppCubit<int>
    with BaseAppCubitState, GoodsSkuApiRoomInfo, GoodsSkuApi {
  GoodsSkuBloc() : super(0);

  State<GoodsSkuDialog>? statePage;

  SkuList? skuList;

  final FocusNode countFocusNode = FocusNode();
  final TextEditingController countController = TextEditingController();

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  /// 已选择组合套餐
  String? selectedCombo;

  void init(State<GoodsSkuDialog> state) {
    statePage = state;
    price.value = statePage!.widget.item.price!;
    image.value = statePage!.widget.item.image!;
    stockNum.value = statePage!.widget.item.quantity!;
    shopGoodsDetail(statePage!.widget.item);

    GoodsLogUp.productSelectPageShow(
        detModel ?? statePage!.widget.item, statePage!.widget.rank,
        roomInfoObject: statePage!.widget.roomInfoObject);

    countFocusNode.addListener(() {
      if (!countFocusNode.hasFocus) {
        inputCount(countController.text);
      }
    });
  }

  /*
  * 输入数量
  * */

  /// 【APP】购买数量数字那里加个数字输入框
  /// 【2021 11.10】
  void inputCount(String countStr) {
    isInputCount.value = false;
    if (!strNoEmpty(countStr)) {
      return;
    }
    currentCount.value = int.parse(countStr);

    if (currentCount.value <= 0) {
      /// 不能小于或等于0
      currentCount.value = 1;
    } else if (currentCount.value > maxCountDet && maxCountDet > 0) {
      /// 判断限购
      currentCount.value = maxCountDet;
    } else if (currentCount.value > stockNum.value) {
      /// 判断库存
      currentCount.value = stockNum.value;
    }

    /// 刷新加号和减号
    handleEnable();
  }

  /*
  * 开始输入数量
  * */
  void enterInputCount() {
    isInputCount.value = true;
    countController.text = '${currentCount.value}';
    countFocusNode.requestFocus();
  }

  /*
  * 是否没有选择规格
  * */
  bool get isUnSelectItem {
    return skuList == null && listNoEmpty(detModel?.skuProps);
  }

  /*
  * 库存不足
  * */
  bool get underStock {
    return currentCount.value > stockNum.value || stockNum.value <= 0;
  }

  String get underStockStr {
    return "商品库存不够无法进行购买";
  }

  /*
  * 总库存为0
  *
  * 【APP】观众点击马上抢商品。当商品库存为0的时候还可以选择规格
  * */
  bool get totalIsNull {
    return (detModel?.quantity ?? statePage!.widget.item.quantity ?? 0) <= 0;
  }

  Future<void> placeAnOrder() async {
    String notInputText = '';

    /// 提交时的message
    final List<String?> messages = [];

    /// 必填留言校验 [2021 11.25新需求]
    for (final GoodsMessageModel element in detModel?.messages ?? []) {
      if (element.required == 1 && !strNoEmpty(element.controller?.text)) {
        notInputText = element.name ?? '';
        break;
      } else {
        messages.add(element.name);
        messages.add(element.controller?.text);
      }
    }

    /// 判断是否有输入完，如果没输入完[notInputText]不等于空
    ///
    /// 【购物车】商品有留言必填项的时候，加入购物车，加入不了，弹出“信息还未填写完整”
    /// 【2021 12.1】
    ///
    /// 添加购物车也需要填写留言&&校验留言填写
    /// 【2021 12.2】
    if (strNoEmpty(notInputText)) {
      myToast('信息还未填写完整');
      return;
    }

    /// 总库存为0，不可以选择规格
    if (totalIsNull) {
      myToast('商品总库存为0');
    } else if (maxCountDet != 0 && currentCount.value > maxCountDet) {
      myFailToast('最多下单$maxCountDet件商品');
    } else if (underStock) {
      myFailToast(underStockStr);
    } else if (currentCount.value < (detModel?.startSaleNum ?? 1)) {
      myFailToast("购买数量低于范围");
    } else if (isUnSelectItem) {
      myFailToast("请选择商品规格");
    } else {
      final okId =
          listNoEmpty(detModel?.skuProps) ? skuList!.skuId : detModel!.spuId;
      if (statePage!.widget.isCar) {
        await liveCartAdd(context, okId, currentCount.value,
            statePage!.widget.addSuccess, messages);
      } else {
        await liveGoodsOrder(context, okId, currentCount.value, messages);
      }

      await GoodsLogUp.clickSelectConfirm(
          detModel ?? statePage!.widget.item, statePage!.widget.rank,
          roomInfoObject: statePage!.widget.roomInfoObject);
    }
  }

  void handlePrice() {
    if (!listNoEmpty(detModel?.skuProps)) {
      return;
    }
    if (!listNoEmpty(detModel?.skuList)) {
      return;
    }

    bool isCanPrice = true;

    /// 清除当前已选择的skuValues列表
    selectValueIdList.clear();
    for (int i = 0; i < detModel!.skuProps!.length; i++) {
      /// 判断当前规格组是否有选择的valueId
      if (detModel!.skuProps![i].selectValueId == null) {
        isCanPrice = false;
      } else {
        /// 规格列表添加当前选择了规格item的Id
        selectValueIdList.add(detModel!.skuProps![i].selectValueId);
      }
    }
    if (!isCanPrice) {
      skuList = null;
      selectedCombo = null;
      return;
    }

    detModel!.skuList!.forEach((element) {
      bool isOkModel = true;
      final List<String?> selectedComboList = [];
      for (int i = 0; i < detModel!.skuProps!.length; i++) {
        if (detModel!.skuProps![i].selectValueId != element.propValues![i]) {
          isOkModel = false;
        } else {
          selectedComboList.add(detModel!.skuProps![i].selectValueName);
        }
      }
      if (isOkModel) {
        /// 组合
        selectedCombo = selectedComboList.join(" + ");

        skuList = element;
        price.value = element.price!;
        stockNum.value = element.stockNum!;

        /// 处理当前购买数量
        if (currentCount.value > stockNum.value) {
          currentCount.value = stockNum.value;
        } else if (currentCount.value == 0 && stockNum.value > 0) {
          currentCount.value = 1;
        }

        /// 刷新加号和减号
        handleEnable();
      }
    });
  }

  @override
  RoomInfon get roomInfoObject => statePage!.widget.roomInfoObject;
}
