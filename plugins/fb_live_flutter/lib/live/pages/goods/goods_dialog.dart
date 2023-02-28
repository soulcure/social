import 'package:fb_live_flutter/live/bloc/goods/goods_dialog_bloc.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_card.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_no_data.dart';
import 'package:fb_live_flutter/live/utils/live/goods_manage_light_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/widget/view/red_dot_page.dart';
import 'package:fb_live_flutter/live/widget_common/view/loading_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'commom/goods_app_bar.dart';
import 'commom/goods_card_parent.dart';
import 'commom/show_goods_dialog.dart';

/// 商品列表对话框
Future goodsDialog(
    BuildContext context, final int? shopId, final RoomInfon roomInfoObject) {
  return showGoodsDialog(
    context,
    child: BlocProvider(
      create: (context) {
        return GoodsDialogBloc();
      },
      child: GoodsDialogPage(shopId, roomInfoObject),
    ),
  );
}

class GoodsDialogPage extends StatefulWidget {
  final int? shopId;
  final RoomInfon roomInfoObject;

  const GoodsDialogPage(this.shopId, this.roomInfoObject);

  @override
  _GoodsDialogPageState createState() => _GoodsDialogPageState();
}

class _GoodsDialogPageState extends State<GoodsDialogPage> {
  final double rate = 609 / 821;

  final GoodsDialogBloc _manageBloc = GoodsDialogBloc();

  Offset? _endOffset;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _manageBloc.init(this);

    WidgetsBinding.instance!.addPostFrameCallback((c) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        // 获取「购物车」的位置
        _endOffset = (_key.currentContext?.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoodsDialogBloc, int>(builder: (context, value) {
      return SizedBox(
        width: FrameSize.winWidth(),
        height: (FrameSize.maxValue() * rate) - 20.px - FrameSize.padBotH(),
        child: Column(
          children: [
            Obx(
              () {
                return GoodsAppBar(
                  title: "可购买商品",
                  items: [
                    GoodsDialogItemModel(
                        'assets/live/main/goods_order_grey.png',
                        '订单',
                        GoodsDialogItemType.order),
                    GoodsDialogItemModel('assets/live/main/goods_car_grey.png',
                        '购物车', GoodsDialogItemType.shoppingCart),
                  ],
                  goodCall: (value) {
                    _manageBloc.action(value);
                  },
                  isShowCartRedPoint: _manageBloc.isShowCartRedPoint.value,
                  cartKey: _key,
                );
              },
            ),

            /// 【APP】快速购买页，上方固定的一栏，与商品列表间距过大
            /// 原本20.px
            // Space(height: 15.px),
            Expanded(
              child: !_manageBloc.isLoadOk
                  ? const LoadingTextView()
                  : !_manageBloc.isHaveData
                      ? const GoodsNoData(isHaveButton: false)
                      : SmartRefresher(
                          enablePullUp: true,
                          enablePullDown: false,
                          footer: const CustomFooterView(),
                          controller: _manageBloc.refreshController,
                          onLoading: () async {
                            _manageBloc.pageNum++;
                            return _manageBloc.liveGoodsList(false);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: _manageBloc.models.length,
                            itemBuilder: (context, index) {
                              /// 【2021 12.17】【商品列表】商品编号，随着分页会变 ，跟主播一样固定编号
                              final int rank =
                                  (_manageBloc.dataCount ?? 0) - index;
                              final item = _manageBloc.models[index];
                              return GoodsCard(
                                  item.quantity! > 0
                                      ? GoodsStatus.ok
                                      : GoodsStatus.gone,
                                  rank,
                                  item, (context) {
                                /// 添加到购物车抛物线动画
                                /// 点击的时候获取当前 widget 的位置，传入 overlayEntry
                                OverlayEntry? _overlayEntry =
                                    OverlayEntry(builder: (_) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final offset = box.localToGlobal(Offset.zero);
                                  return RedDotPage(
                                    startPosition: offset,
                                    endPosition: _endOffset,
                                  );
                                });
                                // 显示Overlay
                                Overlay.of(context)!.insert(_overlayEntry);
                                // 等待动画结束
                                Future.delayed(
                                    const Duration(milliseconds: 700), () {
                                  _overlayEntry!.remove();
                                  _overlayEntry = null;
                                  _manageBloc.isShowCartRedPoint.value = true;

                                  /// 内存添加数量处理
                                  GoodsManageCartUtil.addCount(
                                      _manageBloc.cartCount,
                                      widget.roomInfoObject.roomId);
                                });
                              }, widget.roomInfoObject);
                            },
                          ),
                        ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _manageBloc.close();
  }
}
