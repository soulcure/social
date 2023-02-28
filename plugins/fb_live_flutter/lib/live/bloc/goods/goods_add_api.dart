import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'goods_add_tab_bloc.dart';

abstract class GoodsAddApiRoomInfo {
  RoomInfon get roomInfoObject;
}

mixin GoodsAddApi on BaseAppCubit<int>, BaseAppCubitState, GoodsAddApiRoomInfo {
  int pageNum = 1;
  int? total = 0;

  bool isLoadOk = false;
  bool isAdding = false;

  List<GoodsListModel> models = [];

  final RefreshController refreshController = RefreshController();

  bool get isHaveData {
    return listNoEmpty(models);
  }

  /*
  * 查询店铺商品列表
  * */
  Future<void> shopGoodsList(
      final List<GoodsListModel> okModels, final GoodsAddTabBloc tabBloc,
      {String? keyword, bool? isLive, bool isRefresh = true}) async {
    /// 【2021 10.28】搜索先清除已选择的数据，防止缓存
    ///
    if (strNoEmpty(keyword)) {
      /// [2021 11.18] 数据要联动，不能清楚已选择的数据
      //   tabBloc.selectData.clear();
      // myLoadingToast(tips: '搜索中');
      /// [2021 11.29]【添加商品对话框】搜索中提示 ui中显示
      isLoadOk = false;
      onRefresh();
    }

    if (isRefresh && pageNum != 1) {
      pageNum = 1;
    }

    final value = await Api.shopGoodsList(
      pageNum: pageNum,
      keyword: keyword?.trim(),
      isLive: isLive,
      roomId: roomInfoObject.roomId,
    );
    if (value["code"] != 200) {
      /// [2021 11.29]【添加商品对话框】搜索中提示 ui中显示
      if (strNoEmpty(keyword)) {
        isLoadOk = true;
        onRefresh();
      }
      return;
    }
    total = value['data']['total'];
    final List<GoodsListModel> data =
        List.from(value['data']["data"] ?? []).map<GoodsListModel>((e) {
      final GoodsListModel goodsModel = GoodsListModel.fromJson(e);
      return goodsModel;
    }).toList();

    if (pageNum <= 1) {
      models = data;
      refreshController.loadComplete();
    } else {
      if (listNoEmpty(data)) {
        models.addAll(data);
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
    }

    isLoadOk = true;
    dismissAllToast();
    onRefresh();
    return;
  }

  /*
  * 新增直播间商品
  * */
  Future liveGoodsAdd(final GoodsAddTabBloc tabBloc) async {
    if (tabBloc.selectData.length > 1) {
      isAdding = true;
      onRefresh();
    }
    final List<int?> itemIds = [];
    tabBloc.selectData.forEach(itemIds.add);
    final value = await Api.liveGoodsAdd(itemIds, roomInfoObject.roomId);
    if (value["code"] != 200) {
      isAdding = false;
      onRefresh();
      return;
    }

    dismissAllToast();
    RouteUtil.pop();
    mySuccessToast("添加成功");
    return value;
  }
}
