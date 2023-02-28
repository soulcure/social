import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_add_dialog.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_manage_dialog.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';

import 'goods_dialog_bloc.dart';
import 'goods_manage_api.dart';
import 'goods_push_logic.dart';

class GoodsManageBloc extends BaseAppCubit<int>
    with BaseAppCubitState, GoodsPushLogicRoom, GoodsManageApi, GoodsPushLogic {
  GoodsManageBloc() : super(0);

  State<GoodsManageDialog>? statePage;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  void init(State<GoodsManageDialog> state) {
    statePage = state;

    liveGoodsList();
    initStartCount(roomInfoObjectValue.roomId);
  }

  void checkManage() {
    isManageMode = false;
    onRefresh();
  }

  void selectAll() {
    if (selectData.length >=
        (currentPushID != null ? models.length - 1 : models.length)) {
      selectData.clear();
    } else {
      selectData = models.reversed.toList();
    }

    onRefresh();
  }

  void handleValue(GoodsListModel? v, bool isSelect) {
    if (isSelect) {
      selectData.remove(v);
    } else {
      selectData.add(v);
    }
    onRefresh();
  }

  void action(GoodsDialogItemModel? value) {
    switch (value!.value) {
      case GoodsDialogItemType.add:
        goodsAddDialog(context!, models, statePage!.widget.roomInfoObject)
            .then((value) {
          liveGoodsList(true, false);
        });
        break;
      case GoodsDialogItemType.manage:

        /// 【2021 11。11】
        /// 当点击管理的时候，从已选择的列表删除在推送中的商品
        /// 原因：推送中的商品不可以被删除
        ///
        ///
        /// 【2021 11.18】正在推送的商品，允许被移除，移除的同时取消推送
        Future.delayed(Duration.zero).then((value) {
          isManageMode = !isManageMode;
          onRefresh();
        });
        break;
      default:
        myToast("敬请期待");
        break;
    }
  }

  @override
  void onRefresh() {
    /// 后续考虑去除setState，使用super.onRefresh();
    if (statePage!.mounted) {
      // ignore: invalid_use_of_protected_member
      statePage?.setState(() {});
    }
  }

  @override
  RoomInfon get roomInfoObjectValue => statePage!.widget.roomInfoObject;
}
