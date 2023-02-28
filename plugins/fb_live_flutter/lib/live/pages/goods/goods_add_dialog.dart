import 'dart:async';

import 'package:fb_live_flutter/live/bloc/goods/goods_add_bloc.dart';
import 'package:fb_live_flutter/live/bloc/goods/goods_add_tab_bloc.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_add_model.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/aid/widget/search_edit.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_tab_bar.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_card.dart';
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

import 'commom/goods_title_bar.dart';
import 'commom/show_goods_dialog.dart';

/// 对话框高度比例
const rateValue = 756 / 821;

/// 商品添加【主播/小助手】列表对话框
Future goodsAddDialog(BuildContext context, List<GoodsListModel> models,
    final RoomInfon roomInfoObject) {
  return showGoodsDialog(
    context,
    child: GoodsAddDialog(models, roomInfoObject),
    rateValue: rateValue,
  );
}

class GoodsAddDialog extends StatefulWidget {
  final List<GoodsListModel> models;
  final RoomInfon roomInfoObject;

  const GoodsAddDialog(this.models, this.roomInfoObject);

  @override
  _GoodsAddDialogState createState() => _GoodsAddDialogState();
}

class _GoodsAddDialogState extends State<GoodsAddDialog>
    with TickerProviderStateMixin {
  List<String> tabs = ["直播商品", "全部商品"];
  TabController? tabC;
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  late GoodsAddTabBloc tabBloc;

  @override
  void initState() {
    super.initState();
    tabBloc = GoodsAddTabBloc(widget.roomInfoObject);
    tabC = TabController(length: tabs.length, vsync: this);

    tabC!.addListener(() {
      goodsAddBus
          .fire(GoodsAddTabChangeEvenModel(tabC!.index, controller.text));
    });
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
              const GoodsTitleBar(
                title: "添加商品",
                isClose: true,
              ),
              StatefulBuilder(builder: (context, refresh) {
                return Row(
                  children: [
                    Expanded(
                      child: SearchEdit(
                        text: '搜索',
                        horizontal: 16.px,
                        controller: controller,
                        focusNode: focusNode,
                        onTap: () {
                          refresh(() {});
                        },
                        onSubmitted: (v) {
                          goodsAddBus.fire(GoodsAddEvenModel(tabC!.index, v));
                        },
                        onClean: () {
                          /// 点击清除后显示全部的
                          goodsAddBus.fire(GoodsAddEvenModel(tabC!.index, ''));
                        },
                      ),
                    ),
                    SearchCancelButton(focusNode),
                  ],
                );
              }),
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
                        return GoodsAddBloc();
                      },
                      child: GoodsAddTabPage(
                        tabs[index],
                        index,
                        widget.models,
                        tabBloc,
                        widget.roomInfoObject,
                      ),
                    );
                  }),
                ),
              ),
              GoodsHasChosenState(
                selectData: tabBloc.selectData,
                isConfirm: true,
                onPressed: () async {
                  await tabBloc.liveGoodsAdd(tabBloc);
                },
              )
            ],
          ),
        );
      },
    );
  }
}

class GoodsAddTabPage extends StatefulWidget {
  final String tab;
  final int tabIndex;
  final List<GoodsListModel> models;
  final GoodsAddTabBloc tabBloc;
  final RoomInfon roomInfoObject;

  const GoodsAddTabPage(
      this.tab, this.tabIndex, this.models, this.tabBloc, this.roomInfoObject);

  @override
  _GoodsAddTabPageState createState() => _GoodsAddTabPageState();
}

class _GoodsAddTabPageState extends State<GoodsAddTabPage>
    with AutomaticKeepAliveClientMixin {
  final GoodsAddBloc _manageBloc = GoodsAddBloc();

  StreamSubscription? goodsSubs;
  StreamSubscription? goodsTabChangeSubs;
  StreamSubscription? selectAll;
  StreamSubscription? refreshSubs;

  @override
  void initState() {
    super.initState();
    _manageBloc.init(this);
    goodsTabChangeSubs = goodsAddBus
        .on<GoodsAddTabChangeEvenModel>()
        .listen(_manageBloc.goodsTabChangeSubsHandle);
    goodsSubs =
        goodsAddBus.on<GoodsAddEvenModel>().listen(_manageBloc.goodsSubsHandle);
    selectAll = goodsAddBus.on<SelectAllEventModel>().listen((event) {
      if (event.index != widget.tabIndex) {
        return;
      }

      _manageBloc.selectAll(widget.tabBloc);
    });
    refreshSubs = goodsAddBus.on<GoodsRefreshModel>().listen((event) {
      if (event.index != widget.tabIndex) {
        return;
      }
      _manageBloc.shopGoodsList(widget.models, widget.tabBloc,
          isLive: widget.tabIndex == 0);
    });
  }

  ///4.4.返回设置好的富文本
  Widget _splitChina(String name) {
    final TextStyle _normalStyle = TextStyle(
      color: const Color(0xff646A73),
      fontSize: 13.px,
    );
    final TextStyle _highlightStyle = TextStyle(
      color: const Color(0xFF198CFE),
      fontSize: 13.px,
    );

    final List<TextSpan> spans = [];
    //split 截出来
    final List<String> strS = name.split(_manageBloc.searchText);
    //字符从匹配高亮
    for (int i = 0; i < strS.length; i++) {
      if ((i % 2) == 1) {
        spans.add(
            TextSpan(text: _manageBloc.searchText, style: _highlightStyle));
      }
      final String val = strS[i];
      if (strNoEmpty(val)) {
        spans.add(TextSpan(text: val, style: _normalStyle));
      }
    }
    //返回
    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<GoodsAddBloc, int>(
      builder: (context, value) {
        if (widget.tabBloc.isAdding || _manageBloc.isAdding) {
          return const LoadingTextView("正在添加...");
        }
        if (!_manageBloc.isLoadOk) {
          return const LoadingTextView();
        }
        return Column(
          children: [
            Expanded(
              child: SmartRefresher(
                enablePullUp: true,
                enablePullDown: false,
                footer: const CustomFooterView(mainColor: Colors.grey),
                controller: _manageBloc.refreshController,
                onLoading: () async {
                  _manageBloc.pageNum++;
                  return _manageBloc.shopGoodsList(
                      widget.models, widget.tabBloc,
                      isLive: widget.tabIndex == 0, isRefresh: false);
                },
                child: ListView.builder(
                  /// 【APP】主播添加商品页，下拉至最后一条商品，该商品显示不全
                  padding: EdgeInsets.only(bottom: 50.px),
                  itemCount: _manageBloc.models.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        padding: EdgeInsets.only(
                            left: 16.px, top: 16.px, bottom: 8.px),
                        child: Text(
                          '共 ${_manageBloc.total}个商品',
                          style: TextStyle(
                              color: const Color(0xff646A73), fontSize: 12.px),
                        ),
                      );
                    }
                    final GoodsListModel item = _manageBloc.models[index - 1];
                    final title = item.title ?? '';

                    final int rank = _manageBloc.total! - index + 1;

                    final bool isSelect =
                        widget.tabBloc.selectData.contains(item.itemId);

                    if (!title.contains(_manageBloc.searchText) &&
                        strNoEmpty(_manageBloc.searchText)) {
                      return Container();
                    }

                    return GoodsCheckCard(
                      rank,
                      item: item,
                      isSelect: isSelect,
                      titleW: () {
                        return _splitChina(title);
                      }(),
                      call: (v) =>
                          _manageBloc.handleValue(v, isSelect, widget.tabBloc),
                      roomInfoObject: widget.roomInfoObject,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    goodsSubs?.cancel();
    goodsSubs = null;
    goodsTabChangeSubs?.cancel();
    goodsTabChangeSubs = null;
    selectAll?.cancel();
    selectAll = null;
    refreshSubs?.cancel();
    refreshSubs = null;
  }

  @override
  bool get wantKeepAlive => listNoEmpty(_manageBloc.models);
}
