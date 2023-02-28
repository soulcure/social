import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/goods/goods_dialog_bloc.dart';
import 'package:fb_live_flutter/live/event_bus_model/coupons/coupons_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/coupons_add_dialog.dart';
import 'package:fb_live_flutter/live/pages/coupons/coupons_dialog.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';

import 'coupons_add_api.dart';

class CouponsDialogBloc extends BaseAppCubit<int>
    with BaseAppCubitState, CouponsRoomInfo, CouponsAddApi {
  CouponsDialogBloc() : super(0);

  State<CouponsDialogPage>? statePage;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  StreamSubscription? _refreshBus;

  Future<void> init(State<CouponsDialogPage> state) async {
    statePage = state;
    await liveCouponList(0, isToast: true);

    _refreshBus = couponsBus.on<CouponsRefreshModel>().listen((event) {
      liveCouponList(0, isToast: false);
    });
    return;
  }

  /*
  * 初始化状态
  *
  * 主播端，设置优惠券时，【刷新】按钮，应该是重新加载列表（页面重载）。
  * */
  void initState() {
    isLoadOk = false;
    models = [];
    total = 0;
    onRefresh();
  }

  void action(GoodsDialogItemModel? value) {
    switch (value!.value) {
      case GoodsDialogItemType.add:
        couponsAddDialog(context!, false, models, statePage!.widget.goodsLogic);
        break;
      case GoodsDialogItemType.manage:
        couponsAddDialog(context!, true, models, statePage!.widget.goodsLogic);
        break;
      default:
        myToast("敬请期待");
        break;
    }
  }

  @override
  Future<void> close() {
    _refreshBus?.cancel();
    _refreshBus = null;
    return super.close();
  }

  @override
  RoomInfon get roomInfoObject => statePage!.widget.roomInfoObject;
}
