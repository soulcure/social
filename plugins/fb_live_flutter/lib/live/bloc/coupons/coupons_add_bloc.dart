import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/coupons_add_dialog.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:flutter/material.dart';

import 'coupons_add_api.dart';
import 'coupons_add_tab_bloc.dart';

class CouponsAddBloc extends BaseAppCubit<int>
    with BaseAppCubitState, CouponsRoomInfo, CouponsAddApi {
  CouponsAddBloc() : super(0);

  State<CouponsAddTabPage>? statePage;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  void init(State<CouponsAddTabPage> state) {
    statePage = state;

    if (state.widget.isManage) {
      /// 直播间优惠券列表
      liveCouponList(state.widget.tabIndex, isToast: true);
    } else {
      /// 查询店铺商品列表
      shopCouponList(state.widget.tabIndex, state.widget.okModels);
    }
  }

  /// 【全选】优惠券管理
  void selectAll(final CouponsAddTabBloc tabBloc) {
    if (tabBloc.selectData.length == models.length) {
      tabBloc.selectData.clear();
    } else {
      tabBloc.selectData =
          models.map<int?>((e) => e.id).toList().reversed.toList();
    }
    tabBloc.onRefresh();
  }

  /// 【全选】优惠券添加
  void selectAllNotManage(final CouponsAddTabBloc tabBloc) {
    /// 【添加优惠券】已添加的商品不允许被选择
    int wCount = statePage?.widget.okModels.length ?? 0;
    if (listNoEmpty(statePage!.widget.okModels)) {
      for (int a = 0; a < statePage!.widget.okModels.length; a++) {
        final widgetItem = statePage!.widget.okModels[a];
        bool isNeedSubtract = true;
        for (int i = 0; i < models.length; i++) {
          final cItem = models[i];
          if (cItem.id == widgetItem.id) {
            isNeedSubtract = false;
          }
        }
        if (isNeedSubtract) {
          wCount--;
        }
      }
    }

    if (tabBloc.selectData.length >= (models.length - wCount)) {
      tabBloc.selectData.clear();
    } else {
      tabBloc.selectData =
          models.map<int?>((e) => e.id).toList().reversed.toList();
    }

    if (listNoEmpty(statePage!.widget.okModels)) {
      for (int i = 0; i < statePage!.widget.okModels.length; i++) {
        final CouponListModel element = statePage!.widget.okModels[i];
        for (int a = 0; a < tabBloc.selectData.length; a++) {
          final selectElement = tabBloc.selectData[a];
          if (selectElement == element.id) {
            tabBloc.selectData.remove(selectElement);
          }
        }
      }
    }

    tabBloc.onRefresh();
  }

  void handleValue(
      CouponListModel? v, bool isSelect, final CouponsAddTabBloc tabBloc) {
    if (isSelect) {
      tabBloc.selectData.remove(v!.id);
    } else {
      tabBloc.selectData.add(v!.id);
    }
    tabBloc.onRefresh();
  }

  @override
  RoomInfon get roomInfoObject =>
      statePage!.widget.goodsLogic.getRoomInfoObject!;
}
