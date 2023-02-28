import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_add_model.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_add_dialog.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:flutter/material.dart';

import 'goods_add_api.dart';
import 'goods_add_tab_bloc.dart';

class GoodsAddBloc extends BaseAppCubit<int>
    with BaseAppCubitState, GoodsAddApiRoomInfo, GoodsAddApi {
  GoodsAddBloc() : super(0);

  State<GoodsAddTabPage>? statePage;

  bool isSearchResult = false;
  String searchText = '';
  int? searchCount;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  void init(State<GoodsAddTabPage> state) {
    statePage = state;

    /// 查询店铺商品列表
    shopGoodsList(statePage!.widget.models, statePage!.widget.tabBloc,
        isLive: statePage!.widget.tabIndex == 0);
  }

  void goodsTabChangeSubsHandle(GoodsAddTabChangeEvenModel event) {
    if (event.index != statePage!.widget.tabIndex) {
      return;
    }
    if (isTemporaryTapProcessing) {
      return;
    }
    isTemporaryTapProcessing = true;
    restoreTemporaryProcess();

    /// 当前是搜索结果但搜索关键词从其他tab被删除了再回到当前tab需要刷新；
    /// 【2021 11.19】
    if (isSearchResult && !strNoEmpty(event.searchText)) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        searchText = "";
        searchCount = null;
        isSearchResult = false;

        /// 查询店铺商品列表
        shopGoodsList(statePage!.widget.models, statePage!.widget.tabBloc,
            isLive: statePage!.widget.tabIndex == 0);
      });
    }
  }

  void goodsSubsHandle(GoodsAddEvenModel event) {
    if (event.index != statePage!.widget.tabIndex) {
      return;
    }
    if (strNoEmpty(event.searchText)) {
      searchText = event.searchText;

      isSearchResult = true;

      shopGoodsList(statePage!.widget.models, statePage!.widget.tabBloc,
              keyword: searchText, isLive: statePage!.widget.tabIndex == 0)
          .then((value) {
        searchCount = 0;
        models.forEach((element) {
          final String text = element.title ?? "";
          if (!text.contains(searchText)) {
            return;
          }
          var _searchCount = searchCount;
          if (_searchCount != null) {
            _searchCount++;
            searchCount = _searchCount;
          }
        });
      });
    } else {
      searchText = '';
      searchCount = null;
      isSearchResult = false;
      shopGoodsList(statePage!.widget.models, statePage!.widget.tabBloc,
          isLive: statePage!.widget.tabIndex == 0);
    }
    onRefresh();
  }

  void selectAll(final GoodsAddTabBloc tabBloc) {
    /// 【添加商品】已添加的商品不允许被选择
    int wCount = statePage?.widget.models.length ?? 0;
    if (listNoEmpty(statePage!.widget.models)) {
      for (int a = 0; a < statePage!.widget.models.length; a++) {
        final widgetItem = statePage!.widget.models[a];
        bool isNeedSubtract = true;
        for (int i = 0; i < models.length; i++) {
          final cItem = models[i];
          if (cItem.itemId == widgetItem.itemId) {
            isNeedSubtract = false;
          }
        }
        if (isNeedSubtract) {
          wCount--;
        }
      }
    }

    if (statePage!.widget.tabBloc.selectData.length >=
        (models.length - wCount)) {
      statePage!.widget.tabBloc.selectData.clear();
    } else {
      statePage!.widget.tabBloc.selectData =
          models.map<int?>((e) => e.itemId).toList().reversed.toList();
    }

    if (listNoEmpty(statePage!.widget.models)) {
      for (int i = 0; i < statePage!.widget.models.length; i++) {
        final GoodsListModel element = statePage!.widget.models[i];
        for (int a = 0; a < statePage!.widget.tabBloc.selectData.length; a++) {
          final selectElement = statePage!.widget.tabBloc.selectData[a];
          if (selectElement == element.itemId) {
            statePage!.widget.tabBloc.selectData.remove(selectElement);
          }
        }
      }
    }
    tabBloc.onRefresh();
  }

  void handleValue(
      GoodsListModel? v, bool isSelect, final GoodsAddTabBloc tabBloc) {
    if (isSelect) {
      statePage!.widget.tabBloc.selectData.remove(v!.itemId);
    } else {
      statePage!.widget.tabBloc.selectData.add(v!.itemId);
    }
    tabBloc.onRefresh();
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
  RoomInfon get roomInfoObject => statePage!.widget.roomInfoObject;
}
