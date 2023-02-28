import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fb_live_flutter/live/bloc/goods/goods_manage_bloc.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/goods_title_bar.dart';

import 'package:fb_live_flutter/live/pages/goods/widget/goods_card.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_has_chosen.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_no_data.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_select_all_text.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/widget_common/view/bottom_option_bar.dart';
import 'package:fb_live_flutter/live/widget_common/view/loading_text_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'commom/goods_app_bar.dart';
import 'commom/show_goods_dialog.dart';
import 'goods_add_dialog.dart';

/// 商品管理【主播/小助手】列表对话框
Future goodsManageDialog(
    BuildContext context, bool? isAnchor, RoomInfon roomInfoObject) {
  return showGoodsDialog(
    context,
    child: BlocProvider(
      create: (context) {
        return GoodsManageBloc();
      },
      child: GoodsManageDialog(isAnchor, roomInfoObject),
    ),
  );
}

class GoodsManageDialog extends StatefulWidget {
  final bool? isAnchor;
  final RoomInfon roomInfoObject;

  const GoodsManageDialog(this.isAnchor, this.roomInfoObject);

  @override
  _GoodsManageDialogState createState() => _GoodsManageDialogState();
}

class _GoodsManageDialogState extends State<GoodsManageDialog>
    with AutomaticKeepAliveClientMixin {
  final GoodsManageBloc _manageBloc = GoodsManageBloc();

  @override
  void initState() {
    super.initState();
    _manageBloc.init(this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<GoodsManageBloc, int>(
      builder: (context, value) {
        if (!_manageBloc.isLoadOk) {
          return const LoadingTextView();
        }

        return Stack(
          children: [
            SizedBox(
              height: (FrameSize.maxValue() * 609 / 821) -
                  20.px -
                  FrameSize.padBotH(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_manageBloc.isManageMode && _manageBloc.isHaveData)
                    GoodsTitleBar(
                      title: "管理",
                      onPop: _manageBloc.checkManage,
                      leftSpace: 20,
                      rWidget: InkWell(
                        onTap: _manageBloc.selectAll,
                        child: Container(
                          width: 56.px,
                          height: 44.px,

                          /// 5.px
                          /// 【APP】商品管理页面，全选有点过于靠右，不方便点击
                          padding: EdgeInsets.only(right: 15.px),
                          alignment: Alignment.center,
                          child: GoodsSelectAllText(),
                        ),
                      ),
                    )
                  else
                    GoodsAppBar(
                      title:
                          "商品${_manageBloc.isHaveData ? " (${_manageBloc.dataCount})" : ""}",
                      items: const [],
                      goodCall: _manageBloc.action,
                    ),
                  Expanded(
                    child: !_manageBloc.isHaveData
                        ? GoodsNoData(
                            isHaveButton: true,
                            onTap: () {
                              goodsAddDialog(context, _manageBloc.models,
                                      widget.roomInfoObject)
                                  .then((value) {
                                _manageBloc.liveGoodsList();
                              });
                            })
                        : Padding(
                            /// 差主播商品列表缺少没有更多了
                            padding: _manageBloc.isManageMode
                                ? EdgeInsets.only(bottom: 44.px)
                                : EdgeInsets.only(bottom: 52.px),
                            child: SmartRefresher(
                              enablePullUp: true,
                              enablePullDown: false,
                              footer: const CustomFooterView(),
                              controller: _manageBloc.refreshController,
                              onLoading: () async {
                                _manageBloc.pageNum++;
                                return _manageBloc.liveGoodsList(false);
                              },
                              child: ListView.builder(
                                itemCount: _manageBloc.models.length,
                                itemBuilder: (context, index) {
                                  final int rank =
                                      _manageBloc.dataCount! - index;
                                  final item = _manageBloc.models[index];
                                  if (_manageBloc.isManageMode) {
                                    final bool isSelect =
                                        _manageBloc.selectData.contains(item);

                                    /// 【2021 11.11】正在推送的商品在商品管理不允许选择及删除
                                    ///
                                    /// 【2021 11.18】正在推送的商品，允许被移除，移除的同时取消推送
                                    /// 3.取消商品管理中选择商品时的【商品是否正在推荐中】判断，让其可选；
                                    /// 是否可选的属性为[item.isCanSelect]
                                    return GoodsCheckCard(
                                      rank,
                                      isSelect: isSelect,
                                      item: item,
                                      call: (v) =>
                                          _manageBloc.handleValue(v, isSelect),
                                      cantSelectTip: '商品正在推送中，不可被选择',
                                      roomInfoObject: widget.roomInfoObject,
                                    );
                                  }
                                  final GoodsListModel okItem =
                                      _manageBloc.models[index];
                                  return GoodsPushCard(
                                    rank,
                                    okItem,
                                    (v) {
                                      if (v == "移除") {
                                        _manageBloc
                                            .liveGoodsRemoveItem(index)
                                            .then((value) {
                                          if (value != null && value == 1) {
                                            if (okItem.itemId ==
                                                _manageBloc.currentPushID) {
                                              _manageBloc.cancel();
                                            }
                                          }
                                        });
                                      }
                                      if (v == "取消推送") {
                                        _manageBloc.currentPushID = null;
                                      } else {
                                        _manageBloc.currentPushID = item.itemId;
                                      }
                                    },
                                    _manageBloc,
                                    widget.roomInfoObject,
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            /// 【管理/添加】按钮
            if (_manageBloc.isHaveData && !_manageBloc.isManageMode)
              BottomOptionBar(_manageBloc.action),

            GoodsHasChosen(
              enable: !_manageBloc.isManageMode || !_manageBloc.isHaveData,
              selectData: _manageBloc.selectData,
              onPressed: () {
                /// 推送中商品可移除
                _manageBloc.liveGoodsRemoveSelect(
                    _manageBloc.currentPushID, _manageBloc.count! > 0);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _manageBloc.close();
  }

  @override
  bool get wantKeepAlive => true;
}
