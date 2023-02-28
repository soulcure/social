import 'dart:async';

import 'package:fb_live_flutter/live/bloc/coupons/coupons_add_bloc.dart';
import 'package:fb_live_flutter/live/bloc/coupons/coupons_add_tab_bloc.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_add_model.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_check_box.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_tab_bar.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/goods_title_bar.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/show_goods_dialog.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_has_chosen.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_select_all_text.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/view/loading_text_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 对话框高度比例
const rateValue = 756 / 821;

/// 优惠券 "添加/管理"【主播/小助手】列表对话框
Future couponsAddDialog(BuildContext context, bool isManage,
    List<CouponListModel> models, final GoodsLogic goodsLogic) {
  return showGoodsDialog(
    context,
    child: CouponsAddDialog(isManage, models, goodsLogic),
    rateValue: rateValue,
  );
}

class CouponsAddDialog extends StatefulWidget {
  final bool isManage;
  final List<CouponListModel> models;
  final GoodsLogic goodsLogic;

  const CouponsAddDialog(this.isManage, this.models, this.goodsLogic);

  @override
  _CouponsAddDialogState createState() => _CouponsAddDialogState();
}

class _CouponsAddDialogState extends State<CouponsAddDialog>
    with TickerProviderStateMixin {
  List<String> tabs = ["全部", "满减券", '折扣券', '随机金额券'];
  TabController? tabC;
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  CouponsAddTabBloc tabBloc = CouponsAddTabBloc();

  @override
  void initState() {
    super.initState();
    tabC = TabController(length: tabs.length, vsync: this);
    tabBloc.setRoomInfo(widget.goodsLogic.getRoomInfoObject!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: tabBloc,
      builder: (_, __) {
        return SizedBox(
          height:
              (FrameSize.maxValue() * rateValue) - 20.px - FrameSize.padBotH(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoodsTitleBar(
                title: widget.isManage ? "优惠券管理" : "添加优惠券",
                isClose: !widget.isManage,
              ),
              Space(height: 10.px),
              Row(
                children: [
                  Expanded(
                    child: CouponsTabBar(
                      controller: tabC,
                      tabs: tabs.map((e) {
                        return Tab(text: e);
                      }).toList(),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      goodsAddBus.fire(SelectAllEventModel(tabC!.index));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 17.px, vertical: 13.5.px),
                      child: GoodsSelectAllText(),
                    ),
                  )
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: tabC,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(tabs.length, (index) {
                    return BlocProvider(
                      create: (context) {
                        return CouponsAddBloc();
                      },
                      child: CouponsAddTabPage(
                        tabs[index],
                        index,
                        widget.isManage,
                        widget.models,
                        tabBloc,
                        widget.goodsLogic,
                      ),
                    );
                  }),
                ),
              ),
              GoodsHasChosenState(
                selectData: tabBloc.selectData,
                isConfirm: !widget.isManage,
                onPressed: () async {
                  if (widget.isManage) {
                    await tabBloc.liveCouponRemove(tabBloc);
                  } else {
                    await tabBloc.liveCouponAdd(widget.models, tabBloc);
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }
}

class CouponsAddTabPage extends StatefulWidget {
  final String tab;
  final int tabIndex;
  final bool isManage;
  final List<CouponListModel> okModels;
  final CouponsAddTabBloc tabBloc;
  final GoodsLogic goodsLogic;

  const CouponsAddTabPage(this.tab, this.tabIndex, this.isManage, this.okModels,
      this.tabBloc, this.goodsLogic);

  @override
  _CouponsAddTabPageState createState() => _CouponsAddTabPageState();
}

class _CouponsAddTabPageState extends State<CouponsAddTabPage>
    with AutomaticKeepAliveClientMixin {
  final CouponsAddBloc _manageBloc = CouponsAddBloc();

  StreamSubscription? goodsSubs;
  StreamSubscription? selectAll;
  StreamSubscription? refreshSubs;

  String searchText = '';

  int? searchCount;

  @override
  void initState() {
    super.initState();
    _manageBloc.init(this);
    goodsSubs = goodsAddBus.on<GoodsAddEvenModel>().listen((event) {
      if (event.index != widget.tabIndex) {
        return;
      }
      if (strNoEmpty(event.searchText)) {
        searchText = event.searchText;
        searchCount = 0;
        _manageBloc.models.forEach((element) {
          final String text = element.title ?? "";
          if (!text.contains(searchText)) {
            return;
          }

          var _count = searchCount;
          if (_count != null) {
            _count++;
            searchCount = _count;
          }
        });
      } else {
        searchText = '';
        searchCount = null;
      }
      if (mounted) setState(() {});
    });
    selectAll = goodsAddBus.on<SelectAllEventModel>().listen((event) {
      if (event.index != widget.tabIndex) {
        return;
      }

      if (widget.isManage) {
        _manageBloc.selectAll(widget.tabBloc);
      } else {
        _manageBloc.selectAllNotManage(widget.tabBloc);
      }
    });
    refreshSubs = goodsAddBus.on<GoodsRefreshModel>().listen((event) {
      if (event.index != widget.tabIndex) {
        return;
      }
      _manageBloc.shopCouponList(0, widget.okModels);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CouponsAddBloc, int>(
      builder: (context, value) {
        if (!_manageBloc.isLoadOk) {
          return const LoadingTextView();
        }
        return SmartRefresher(
          enablePullUp: true,
          enablePullDown: false,
          footer: const CustomFooterView(),
          controller: _manageBloc.refreshController,
          onLoading: () async {
            _manageBloc.pageNum++;

            if (widget.isManage) {
              /// 直播间优惠券列表
              return _manageBloc.liveCouponList(widget.tabIndex,
                  isToast: true, isRefresh: false);
            } else {
              /// 查询店铺商品列表
              return _manageBloc.shopCouponList(
                  widget.tabIndex, widget.okModels,
                  isRefresh: false);
            }
          },
          child: ListView.builder(
            /// 【APP】主播添加商品页，下拉至最后一条商品，该商品显示不全
            padding: EdgeInsets.only(bottom: 50.px),
            itemCount: _manageBloc.models.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding:
                      EdgeInsets.only(left: 16.px, top: 16.px, bottom: 8.px),
                  child: Text(
                    /// 【APP】优惠卷管理共计多少商品文案错误
                    '共 ${_manageBloc.total}个优惠券',
                    style: TextStyle(
                        color: const Color(0xff646A73), fontSize: 12.px),
                  ),
                );
              }
              final CouponListModel item = _manageBloc.models[index - 1];
              final title = item.title ?? '';

              final int rank = _manageBloc.total! - index + 1;

              final bool isSelect = widget.tabBloc.selectData.contains(item.id);

              if (!title.contains(searchText) && strNoEmpty(searchText)) {
                return Container();
              }

              return CouponsCheckBox(
                rank,
                item: item,
                isSelect: isSelect,
                call: (v) =>
                    _manageBloc.handleValue(v, isSelect, widget.tabBloc),
                goodsLogic: widget.goodsLogic,
              );
            },
          ),
        );
      },
      bloc: _manageBloc,
    );
  }

  @override
  void dispose() {
    super.dispose();
    goodsSubs?.cancel();
    goodsSubs = null;
    selectAll?.cancel();
    selectAll = null;
    refreshSubs?.cancel();
    refreshSubs = null;
  }

  @override
  bool get wantKeepAlive => listNoEmpty(_manageBloc.models);
}
